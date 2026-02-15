#!/usr/bin/env node
import { FabricGateway } from './fabric-sdk/gateway';
import { ChaincodeOperations } from './fabric-sdk/chaincode-operations';

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];

async function main() {
    const gateway = new FabricGateway();
    
    try {
        await gateway.connect('org1', 'tradechannel1');
        const ops = new ChaincodeOperations(gateway);

        switch (command) {
            case 'create-merchant': {
                const [id, type, taxId, balance] = args.slice(1);
                const result = await ops.createMerchant(id, type, taxId, parseFloat(balance));
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'add-products': {
                const [merchantId, productsJson] = args.slice(1);
                const products = JSON.parse(productsJson);
                const result = await ops.addProductsToMerchant(merchantId, products);
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'create-customers': {
                const [customersJson] = args.slice(1);
                const customers = JSON.parse(customersJson);
                const result = await ops.createCustomers(customers);
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'buy-product': {
                const [customerId, productId] = args.slice(1);
                const result = await ops.buyProduct(customerId, productId);
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'deposit-merchant': {
                const [merchantId, amount] = args.slice(1);
                const result = await ops.depositToMerchant(merchantId, parseFloat(amount));
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'deposit-customer': {
                const [customerId, amount] = args.slice(1);
                const result = await ops.depositToCustomer(customerId, parseFloat(amount));
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case 'query-products': {
                const [name, productId, merchantType, maxPrice] = args.slice(1);
                const result = await ops.queryProducts(
                    name || '',
                    productId || '',
                    merchantType || '',
                    parseFloat(maxPrice) || -1
                );
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            default:
                console.error(`Unknown command: ${command}`);
                printUsage();
                process.exit(1);
        }

        await gateway.disconnect();
        process.exit(0);
    } catch (error: any) {
        console.error('Error:', error.message);
        await gateway.disconnect();
        process.exit(1);
    }
}

function printUsage() {
    console.log(`
Usage: npm run cli <command> [args...]

Commands:
  create-merchant <id> <type> <taxId> <balance>
  get-merchant <id>
  add-products <merchantId> '<productsJson>'
  create-customers '<customersJson>'
  buy-product <customerId> <productId>
  deposit-merchant <merchantId> <amount>
  deposit-customer <customerId> <amount>
  query-products [name] [productId] [merchantType] [maxPrice]

Examples:
  npm run cli create-merchant M001 SUPERMARKET 123456 50000
  npm run cli get-merchant M001
  npm run cli buy-product C001 P001
    `);
}

if (args.length === 0) {
    printUsage();
    process.exit(1);
}

main();
