#!/usr/bin/env node
import { ChaincodeOperations } from '../fabric-sdk/chaincode-operations';

interface Args {
    org: 'org1' | 'org2' | 'org3';
    channel: string;
    identity: string;
    op: string;
    params: Record<string, string>;
}

const usage = `Usage: trade-cli --org <org1|org2|org3> --op <operation> [--channel <channel>] [--identity <label>] [operation args]\n\nOperations:\n  create-merchant --id <id> --type <type> --taxId <taxId> --balance <amount>\n  add-products --merchantId <id> --products <json-array>\n  create-customers --customers <json-array>\n  buy-product --customerId <id> --productId <id>\n  deposit-merchant --merchantId <id> --amount <amount>\n  deposit-customer --customerId <id> --amount <amount>\n  query-products [--name <name>] [--productId <id>] [--merchantType <type>] [--maxPrice <number>]\n  merchant-exists --merchantId <id>\n`;

function parseArgs(argv: string[]): Args {
    const params: Record<string, string> = {};
    for (let i = 0; i < argv.length; i += 1) {
        const token = argv[i];
        if (!token.startsWith('--')) {
            continue;
        }
        const key = token.replace(/^--/, '');
        const value = argv[i + 1];
        if (!value || value.startsWith('--')) {
            params[key] = 'true';
            continue;
        }
        params[key] = value;
        i += 1;
    }

    const org = params.org as Args['org'];
    const op = params.op;
    if (!org || !op) {
        throw new Error(usage);
    }

    const channel = params.channel || 'tradechannel1';
    const identity = params.identity || `Admin@${org}.trade.com`;

    return {
        org,
        channel,
        identity,
        op,
        params
    };
}

function parseJsonArray(raw: string | undefined, label: string): any[] {
    if (!raw) {
        throw new Error(`Missing ${label} JSON array.`);
    }
    try {
        const parsed = JSON.parse(raw);
        if (!Array.isArray(parsed)) {
            throw new Error(`${label} must be a JSON array.`);
        }
        return parsed;
    } catch (error: any) {
        throw new Error(`Invalid ${label} JSON: ${error.message}`);
    }
}

async function main(): Promise<void> {
    try {
        const { org, channel, identity, op, params } = parseArgs(process.argv.slice(2));
        const ops = new ChaincodeOperations();

        switch (op) {
            case 'create-merchant': {
                const { id, type, taxId, balance } = params;
                if (!id || !type || !taxId || !balance) {
                    throw new Error(usage);
                }
                const result = await ops.createMerchant(org, channel, identity, id, type, taxId, Number(balance));
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'add-products': {
                const { merchantId, products } = params;
                if (!merchantId) {
                    throw new Error(usage);
                }
                const parsedProducts = parseJsonArray(products, 'products');
                const result = await ops.addProductsToMerchant(org, channel, identity, merchantId, parsedProducts);
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'create-customers': {
                const parsedCustomers = parseJsonArray(params.customers, 'customers');
                const result = await ops.createCustomers(org, channel, identity, parsedCustomers);
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'buy-product': {
                const { customerId, productId } = params;
                if (!customerId || !productId) {
                    throw new Error(usage);
                }
                const result = await ops.buyProduct(org, channel, identity, customerId, productId);
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'deposit-merchant': {
                const { merchantId, amount } = params;
                if (!merchantId || !amount) {
                    throw new Error(usage);
                }
                const result = await ops.depositToMerchant(org, channel, identity, merchantId, Number(amount));
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'deposit-customer': {
                const { customerId, amount } = params;
                if (!customerId || !amount) {
                    throw new Error(usage);
                }
                const result = await ops.depositToCustomer(org, channel, identity, customerId, Number(amount));
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'query-products': {
                const name = params.name || '';
                const productId = params.productId || '';
                const merchantType = params.merchantType || '';
                const maxPrice = params.maxPrice ? Number(params.maxPrice) : -1;
                const result = await ops.queryProducts(org, channel, identity, name, productId, merchantType, maxPrice);
                console.log(JSON.stringify(result, null, 2));
                break;
            }
            case 'merchant-exists': {
                const { merchantId } = params;
                if (!merchantId) {
                    throw new Error(usage);
                }
                const result = await ops.merchantExists(org, channel, identity, merchantId);
                console.log(JSON.stringify({ merchantId, exists: result }, null, 2));
                break;
            }
            default:
                throw new Error(usage);
        }
    } catch (error: any) {
        console.error(error.message || error);
        process.exit(1);
    }
}

main();
