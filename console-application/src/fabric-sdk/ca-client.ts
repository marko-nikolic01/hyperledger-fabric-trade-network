import FabricCAServices from 'fabric-ca-client';
import { Wallets, X509Identity } from 'fabric-network';
import * as path from 'path';
import * as fs from 'fs';

export interface EnrollUserRequest {
    orgName: 'org1' | 'org2' | 'org3';
    userId: string;
    userSecret: string;
    affiliation?: string;
    role?: string;
}

export class FabricCAClient {
    private getCaConfig(orgName: 'org1' | 'org2' | 'org3'): { caURL: string; caName: string; tlsCert: Buffer } {
        const orgConfig = {
            org1: { host: 'localhost', port: 7054, caName: 'ca-org1' },
            org2: { host: 'localhost', port: 8054, caName: 'ca-org2' },
            org3: { host: 'localhost', port: 9054, caName: 'ca-org3' },
        }[orgName];

        const caCertPath = path.resolve(__dirname, '..', '..', '..', 'network', 'fabric-ca', orgName, 'ca-cert.pem');
        if (!fs.existsSync(caCertPath)) {
            throw new Error(`CA certificate not found at ${caCertPath}. Ensure tn up has initialized CAs.`);
        }

        return {
            caURL: `https://${orgConfig.host}:${orgConfig.port}`,
            caName: orgConfig.caName,
            tlsCert: fs.readFileSync(caCertPath)
        };
    }

    private getWalletPath(): string {
        return path.join(process.cwd(), 'wallet');
    }

    private buildMspId(orgName: string): string {
        return `${orgName.charAt(0).toUpperCase() + orgName.slice(1)}MSP`;
    }

    private async ensureCaAdmin(
        wallet: any,
        orgName: 'org1' | 'org2' | 'org3',
        force: boolean = false
    ): Promise<X509Identity> {
        const adminLabel = `ca-admin@${orgName}.trade.com`;
        const existing = await wallet.get(adminLabel);
        if (existing && !force) {
            return existing as X509Identity;
        }

        const { caURL, caName, tlsCert } = this.getCaConfig(orgName);
        const caService = new FabricCAServices(caURL, { trustedRoots: tlsCert, verify: true }, caName);

        const enrollment = await caService.enroll({ enrollmentID: 'admin', enrollmentSecret: 'adminpw' });
        const identity: X509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: this.buildMspId(orgName),
            type: 'X.509',
        };

        await wallet.put(adminLabel, identity);
        return identity;
    }

    async registerAndEnrollUser(request: EnrollUserRequest): Promise<void> {
        const wallet = await Wallets.newFileSystemWallet(this.getWalletPath());
        const userLabel = `${request.userId}@${request.orgName}.trade.com`;
        const existing = await wallet.get(userLabel);
        if (existing) {
            throw new Error(`Identity ${userLabel} already exists in wallet.`);
        }

        const { caURL, caName, tlsCert } = this.getCaConfig(request.orgName);
        const caService = new FabricCAServices(caURL, { trustedRoots: tlsCert, verify: true }, caName);

        const affiliation = request.affiliation ?? `${request.orgName}.department1`;
        const rootAffiliation = affiliation.split('.')[0];

        const registerUser = async (adminUser: any) => {
            const affiliationService = caService.newAffiliationService();
            try {
                await affiliationService.create({ name: rootAffiliation, force: true }, adminUser);
            } catch (error) {}

            try {
                await affiliationService.create({ name: affiliation, force: true }, adminUser);
            } catch (error) {}

            return caService.register({
                enrollmentID: request.userId,
                enrollmentSecret: request.userSecret,
                affiliation,
                role: request.role ?? 'client'
            }, adminUser);
        };

        const adminIdentity = await this.ensureCaAdmin(wallet, request.orgName);
        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        let adminUser = await provider.getUserContext(adminIdentity, `ca-admin@${request.orgName}.trade.com`);

        let secret: string;
        try {
            secret = await registerUser(adminUser);
        } catch (error: any) {
            const message = error?.message ?? '';
            if (message.includes('Authorization failure') || message.includes('code: 71')) {
                const refreshedAdmin = await this.ensureCaAdmin(wallet, request.orgName, true);
                adminUser = await provider.getUserContext(refreshedAdmin, `ca-admin@${request.orgName}.trade.com`);
                secret = await registerUser(adminUser);
            } else {
                throw error;
            }
        }

        const enrollment = await caService.enroll({
            enrollmentID: request.userId,
            enrollmentSecret: secret || request.userSecret
        });

        const userIdentity: X509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: this.buildMspId(request.orgName),
            type: 'X.509',
        };

        await wallet.put(userLabel, userIdentity);
    }
}
