#!/usr/bin/env node
import { FabricCAClient } from '../fabric-sdk/ca-client';

interface CliArgs {
    org1Id: string;
    org1Secret: string;
    org2Id: string;
    org2Secret: string;
    org3Id: string;
    org3Secret: string;
    role?: string;
    affiliationOrg1?: string;
    affiliationOrg2?: string;
    affiliationOrg3?: string;
}

function parseArgs(argv: string[]): CliArgs {
    const args: Record<string, string> = {};
    for (let i = 0; i < argv.length; i += 1) {
        const token = argv[i];
        if (token.startsWith('--')) {
            const key = token.replace(/^--/, '');
            const value = argv[i + 1];
            args[key] = value;
            i += 1;
        }
    }

    return {
        org1Id: args.org1Id || 'user1',
        org1Secret: args.org1Secret || 'user1pw',
        org2Id: args.org2Id || 'user2',
        org2Secret: args.org2Secret || 'user2pw',
        org3Id: args.org3Id || 'user3',
        org3Secret: args.org3Secret || 'user3pw',
        role: args.role,
        affiliationOrg1: args.affiliationOrg1 || 'org1.department1',
        affiliationOrg2: args.affiliationOrg2 || 'org2.department1',
        affiliationOrg3: args.affiliationOrg3 || 'org3.department1'
    };
}

async function enrollOne(orgName: 'org1' | 'org2' | 'org3', userId: string, userSecret: string, affiliation?: string, role?: string): Promise<void> {
    const caClient = new FabricCAClient();
    await caClient.registerAndEnrollUser({
        orgName,
        userId,
        userSecret,
        affiliation,
        role
    });
    console.log(`User ${userId} enrolled for ${orgName} and added to wallet.`);
}

async function main() {
    try {
        const args = parseArgs(process.argv.slice(2));

        await enrollOne('org1', args.org1Id, args.org1Secret, args.affiliationOrg1, args.role);
        await enrollOne('org2', args.org2Id, args.org2Secret, args.affiliationOrg2, args.role);
        await enrollOne('org3', args.org3Id, args.org3Secret, args.affiliationOrg3, args.role);
    } catch (error: any) {
        console.error(`Failed to enroll test users: ${error.message}`);
        process.exit(1);
    }
}

main();
