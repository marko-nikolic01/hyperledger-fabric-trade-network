#!/usr/bin/env node
import { FabricCAClient } from '../fabric-sdk/ca-client';

interface CliArgs {
    org: 'org1' | 'org2' | 'org3';
    id: string;
    secret: string;
    affiliation?: string;
    role?: string;
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

    if (!args.org || !args.id || !args.secret) {
        throw new Error('Usage: enroll-user --org <org1|org2|org3> --id <userId> --secret <password> [--affiliation <org.department1>] [--role <client|peer|admin>]');
    }

    return {
        org: args.org as 'org1' | 'org2' | 'org3',
        id: args.id,
        secret: args.secret,
        affiliation: args.affiliation,
        role: args.role
    };
}

async function main() {
    try {
        const { org, id, secret, affiliation, role } = parseArgs(process.argv.slice(2));
        const caClient = new FabricCAClient();
        await caClient.registerAndEnrollUser({
            orgName: org,
            userId: id,
            userSecret: secret,
            affiliation,
            role
        });
        console.log(`User ${id} enrolled and added to wallet.`);
    } catch (error: any) {
        console.error(`Failed to enroll user: ${error.message}`);
        process.exit(1);
    }
}

main();
