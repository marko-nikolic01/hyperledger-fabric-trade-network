import { Gateway, Wallets, Contract, Network, X509Identity } from 'fabric-network';
import * as path from 'path';
import * as fs from 'fs';

export class FabricGateway {
    private gateway: Gateway | null = null;
    private network: Network | null = null;
    private contract: Contract | null = null;

    // This function connects to Fabric network using admin identity
    async connect(orgName: string = 'org1', channelName: string = 'tradechannel1'): Promise<void> {
        try {
            console.log(`\nConnecting to Fabric network as Admin@${orgName}...`);

            const walletPath = path.join(process.cwd(), 'wallet');
            const wallet = await Wallets.newFileSystemWallet(walletPath);

            const identityLabel = `Admin@${orgName}.trade.com`;
            let identity = await wallet.get(identityLabel);

            if (!identity) {
                console.log(`Identity not found in wallet. Loading from crypto-config...`);
                identity = await this.loadIdentityFromCryptoConfig(wallet, orgName);
            }

            const ccp = this.buildConnectionProfile(orgName);

            this.gateway = new Gateway();
            await this.gateway.connect(ccp, {
                wallet,
                identity: identityLabel,
                discovery: { enabled: true, asLocalhost: true }
            });

            this.network = await this.gateway.getNetwork(channelName);

            this.network = await this.gateway.getNetwork(channelName);
            this.contract = this.network.getContract('trading');

            console.log(`Connected to network as admin-${orgName} on channel ${channelName}`);
        } catch (error) {
            console.error(`Failed to connect to network:`, error);
            throw error;
        }
    }

    private async loadIdentityFromCryptoConfig(wallet: any, orgName: string): Promise<X509Identity> {
        const credPath = path.join(__dirname, '..', '..', '..', 'network', 'crypto-config', 'peerOrganizations', `${orgName}.trade.com`, 'users', `Admin@${orgName}.trade.com`, 'msp');
        const certPath = path.join(credPath, 'signcerts', `Admin@${orgName}.trade.com-cert.pem`);
        const keyPath = path.join(credPath, 'keystore');

        if (!fs.existsSync(certPath)) {
            throw new Error(`Certificate not found at: ${certPath}`);
        }

        if (!fs.existsSync(keyPath)) {
            throw new Error(`Keystore directory not found at: ${keyPath}`);
        }

        const certificate = fs.readFileSync(certPath, 'utf8');

        const keyFiles = fs.readdirSync(keyPath);
        if (keyFiles.length === 0) {
            throw new Error(`No private key found in: ${keyPath}`);
        }

        const privateKeyPath = path.join(keyPath, keyFiles[0]);
        const privateKey = fs.readFileSync(privateKeyPath, 'utf8');

        const orgNameCap = orgName.charAt(0).toUpperCase() + orgName.slice(1); // Org1, Org2, Org3
        const mspId = `${orgNameCap}MSP`;

        const identity: X509Identity = {
            credentials: {
                certificate,
                privateKey,
            },
            mspId,
            type: 'X.509',
        };

        const identityLabel = `Admin@${orgName}.trade.com`;
        await wallet.put(identityLabel, identity);

        console.log(`✅ Identity loaded and saved to wallet as ${identityLabel}`);
        return identity;
    }

    private buildConnectionProfile(orgName: string): any {
        const orgNameCap = orgName.charAt(0).toUpperCase() + orgName.slice(1);
        
        const peerPorts: Record<string, number> = {
            'org1': 7051,
            'org2': 9051,
            'org3': 13051,
        };

        const peerPort = peerPorts[orgName];
        const peerName = `peer0.${orgName}.trade.com`;

        const tlsCertPath = path.resolve(__dirname, '..', '..', '..', 'network', 'crypto-config', 'peerOrganizations', `${orgName}.trade.com`, 'peers', peerName, 'tls', 'ca.crt');

        return {
            name: `trading-network-${orgName}`,
            version: '1.0.0',
            client: {
                organization: orgNameCap,
                connection: {
                    timeout: {
                        peer: {
                            endorser: '300'
                        }
                    }
                }
            },
            organizations: {
                [orgNameCap]: {
                    mspid: `${orgNameCap}MSP`,
                    peers: [peerName]
                }
            },
            peers: {
                [peerName]: {
                    url: `grpcs://localhost:${peerPort}`,
                    tlsCACerts: {
                        path: tlsCertPath
                    },
                    grpcOptions: {
                        'ssl-target-name-override': peerName,
                        'hostnameOverride': peerName
                    }
                }
            }
        };
    }

    async evaluateTransaction(functionName: string, ...args: string[]): Promise<string> {
        if (!this.contract) {
            throw new Error('Not connected to network. Call connect() first.');
        }

        try {
            const result = await this.contract.evaluateTransaction(functionName, ...args);
            return result.toString();
        } catch (error) {
            console.error(`❌ Failed to evaluate transaction ${functionName}:`, error);
            throw error;
        }
    }

    async submitTransaction(functionName: string, ...args: string[]): Promise<string> {
        if (!this.contract) {
            throw new Error('Not connected to network. Call connect() first.');
        }

        try {
            const result = await this.contract.submitTransaction(functionName, ...args);
            return result.toString();
        } catch (error) {
            console.error(`❌ Failed to submit transaction ${functionName}:`, error);
            throw error;
        }
    }

    async disconnect(): Promise<void> {
        if (this.gateway) {
            await this.gateway.disconnect();
            console.log('✅ Disconnected from network');
        }
    }

    getContract(): Contract {
        if (!this.contract) {
            throw new Error('Not connected to network');
        }
        return this.contract;
    }
}