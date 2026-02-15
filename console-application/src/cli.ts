#!/usr/bin/env node
import { ChaincodeOperations } from './fabric-sdk/chaincode-operations';

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];

async function main() {
    try {
        const orgName = process.env.ORG_NAME || 'org1';
        const channelName = process.env.CHANNEL_NAME || 'tradechannel1';
        const identityLabel = process.env.IDENTITY_LABEL || `Admin@${orgName}.trade.com`;
        const ops = new ChaincodeOperations();

        switch (command) {
            case 'create-merchant': {
                const [id, type, taxId, balance] = args.slice(1);
                const result = await ops.createMerchant(
                    orgName,
                    channelName,
                    identityLabel,
                    id,
                    type,
                    taxId,
                    parseFloat(balance)
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'add-products': {
                const [merchantId, productsJson] = args.slice(1);
                const products = JSON.parse(productsJson);
                const result = await ops.addProductsToMerchant(
                    orgName,
                    channelName,
                    identityLabel,
                    merchantId,
                    products
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'create-customers': {
                const [customersJson] = args.slice(1);
                const customers = JSON.parse(customersJson);
                const result = await ops.createCustomers(
                    orgName,
                    channelName,
                    identityLabel,
                    customers
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'buy-product': {
                const [customerId, productId] = args.slice(1);
                const result = await ops.buyProduct(
                    orgName,
                    channelName,
                    identityLabel,
                    customerId,
                    productId
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'deposit-merchant': {
                const [merchantId, amount] = args.slice(1);
                const result = await ops.depositToMerchant(
                    orgName,
                    channelName,
                    identityLabel,
                    merchantId,
                    parseFloat(amount)
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'deposit-customer': {
                const [customerId, amount] = args.slice(1);
                const result = await ops.depositToCustomer(
                    orgName,
                    channelName,
                    identityLabel,
                    customerId,
                    parseFloat(amount)
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'query-products': {
                const [name, productId, merchantType, maxPrice] = args.slice(1);
                const parsedMaxPrice = maxPrice ? Number(maxPrice) : -1;
                const result = await ops.queryProducts(
                    orgName,
                    channelName,
                    identityLabel,
                    name || '',
                    productId || '',
                    merchantType || '',
                    Number.isFinite(parsedMaxPrice) ? parsedMaxPrice : -1
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            default:
                console.error(`Unknown command: ${command}`);
                printUsage();
                process.exit(1);
        }

        process.exit(0);
    } catch (error: any) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

function printUsage() {
    console.log(`
Usage: npm run cli <command> [args...]

Commands:
  create-merchant <id> <type> <taxId> <balance>
  add-products <merchantId> '<productsJson>'
  create-customers '<customersJson>'
  buy-product <customerId> <productId>
  deposit-merchant <merchantId> <amount>
  deposit-customer <customerId> <amount>
  query-products [name] [productId] [merchantType] [maxPrice]

Examples:
  npm run cli create-merchant M001 SUPERMARKET 123456 50000
  npm run cli buy-product C001 P001
    `);
}

if (args.length === 0) {
    printUsage();
    process.exit(1);
}

main();
