#!/usr/bin/env node
import { FabricGateway } from '../fabric-sdk/gateway';

interface CliArgs {
    org: 'org1' | 'org2' | 'org3';
    channel: string;
    identity?: string;
    functionName: string;
    args: string[];
    evaluate: boolean;
}

function parseArgs(argv: string[]): CliArgs {
    const args: Record<string, string | string[]> = {};
    for (let i = 0; i < argv.length; i += 1) {
        const token = argv[i];
        if (!token.startsWith('--')) {
            continue;
        }
        const key = token.replace(/^--/, '');
        if (key === 'arg') {
            const value = argv[i + 1];
            if (!value) {
                throw new Error('Missing value for --arg');
            }
            if (!args[key]) {
                args[key] = [];
            }
            (args[key] as string[]).push(value);
            i += 1;
            continue;
        }
        const value = argv[i + 1];
        if (!value || value.startsWith('--')) {
            args[key] = 'true';
            continue;
        }
        args[key] = value;
        i += 1;
    }

    const org = args.org as CliArgs['org'];
    const channel = (args.channel as string) ?? 'tradechannel1';
    const functionName = args.function as string;

    if (!org || !functionName) {
        throw new Error('Usage: invoke-chaincode --org <org1|org2|org3> --function <fn> [--channel <channel>] [--identity <label>] [--args "a,b,c"] [--arg <value> ...] [--evaluate]');
    }

    const argsList: string[] = [];
    const csvArgs = args.args as string | undefined;
    if (csvArgs) {
        argsList.push(...csvArgs.split(',').map((item) => item.trim()).filter(Boolean));
    }
    const repeatedArgs = args.arg as string[] | undefined;
    if (repeatedArgs) {
        argsList.push(...repeatedArgs);
    }

    return {
        org,
        channel,
        identity: args.identity as string | undefined,
        functionName,
        args: argsList,
        evaluate: args.evaluate === 'true'
    };
}

async function main() {
    try {
        const { org, channel, identity, functionName, args, evaluate } = parseArgs(process.argv.slice(2));
        const gateway = new FabricGateway();
        await gateway.connect(org, channel, identity);

        const result = evaluate
            ? await gateway.evaluateTransaction(functionName, ...args)
            : await gateway.submitTransaction(functionName, ...args);

        try {
            const parsed = JSON.parse(result);
            console.log(JSON.stringify(parsed, null, 2));
        } catch {
            console.log(result);
        }

        await gateway.disconnect();
    } catch (error: any) {
        console.error(`Failed to invoke chaincode: ${error.message}`);
        process.exit(1);
    }
}

main();
