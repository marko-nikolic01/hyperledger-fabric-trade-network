#!/usr/bin/env node
import { MenuOption, promptCustomerData, promptDepositData, promptMerchantData, promptProductData, promptProductSearch, showMenu, waitForEnter } from './console-management/menu';
import { confirmSensitiveOperation, getCommandForOption } from './console-management/menu-commands';
import { executeCommand } from './command-executor/executor';
import { FabricGateway } from './fabric-sdk/gateway';
import { ChaincodeOperations } from './fabric-sdk/chaincode-operations';

let gateway: FabricGateway | null = null;
let chaincodeOps: ChaincodeOperations | null = null;

async function ensureConnected(): Promise<ChaincodeOperations> {
    if (!gateway || !chaincodeOps) {
        console.log('\nConnecting to Fabric network...');
        gateway = new FabricGateway();
        await gateway.connect('org1', 'tradechannel1');
        chaincodeOps = new ChaincodeOperations(gateway);
    }
    return chaincodeOps;
}

async function handleSDKOperation(choice: MenuOption): Promise<void> {
    try {
        const ops = await ensureConnected();

        switch (choice) {
            case MenuOption.CREATE_MERCHANT: {
                const data = await promptMerchantData();
                const result = await ops.createMerchant(
                    data.id,
                    data.type,
                    data.taxId,
                    data.accountBalance
                );
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.ADD_PRODUCTS: {
                const productData = await promptProductData();
                const products = [{
                    id: productData.id,
                    name: productData.name,
                    price: productData.price,
                    quantity: productData.quantity,
                    expirationDate: productData.expirationDate,
                    merchantId: productData.merchantId
                }];
                const result = await ops.addProductsToMerchant(productData.merchantId, products);
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.CREATE_CUSTOMERS: {
                const customerData = await promptCustomerData();
                const customers = [{
                    id: customerData.id,
                    firstName: customerData.firstName,
                    lastName: customerData.lastName,
                    email: customerData.email,
                    accountBalance: customerData.accountBalance,
                    invoices: []
                }];
                const result = await ops.createCustomers(customers);
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.BUY_PRODUCTS: {
                const customerId = await promptForId('Customer');
                const productId = await promptForId('Product');
                const result = await ops.buyProduct(customerId, productId);
                console.log('\nPurchase Result:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.DEPOSIT_TO_MERCHANT: {
                const data = await promptDepositData('merchant');
                const result = await ops.depositToMerchant(data.id, data.amount);
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.DEPOSIT_TO_CUSTOMER: {
                const data = await promptDepositData('customer');
                const result = await ops.depositToCustomer(data.id, data.amount);
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.QUERY_PRODUCTS: {
                const searchParams = await promptProductSearch();
                const results = await ops.queryProducts(
                    searchParams.name,
                    searchParams.productId,
                    searchParams.merchantType,
                    searchParams.maxPrice
                );
                console.log('\nSearch Results:');
                console.log(JSON.stringify(results, null, 2));
                break;
            }

            default:
                console.log('Operation not yet implemented');
        }
    } catch (error: any) {
        console.error('\nOperation failed:', error.message);
    }
}

async function promptForId(entityType: string): Promise<string> {
    const inquirer = (await import('inquirer')).default;
    const { id } = await inquirer.prompt([
        {
            type: 'input',
            name: 'id',
            message: `Enter ${entityType} ID:`,
            validate: (input: string) => input.trim() ? true : `${entityType} ID cannot be empty`
        }
    ]);
    return id.trim();
}

async function handleMenuChoice(choice: MenuOption): Promise<boolean> {
    if (choice === MenuOption.EXIT) {
        console.log('\nExiting...\n');
        if (gateway) {
            await gateway.disconnect();
        }
        return false;
    }

    const command = getCommandForOption(choice);
    
    if (command) {
        if (choice === MenuOption.STOP_NETWORK) {
            const confirmed = await confirmSensitiveOperation(
                'stop the network',
                'This will stop all running containers.'
            );
            if (!confirmed) {
                console.log('\nOperation cancelled');
                await waitForEnter();
                return true;
            }
        } else if (choice === MenuOption.CLEAN_NETWORK) {
            const confirmed = await confirmSensitiveOperation(
                'clean the network',
                'WARNING: This will remove all generated artifacts and Docker volumes (including ledger data).'
            );
            if (!confirmed) {
                console.log('\nOperation cancelled');
                await waitForEnter();
                return true;
            }
        }

        executeCommand(command);
    } else {
        await handleSDKOperation(choice);
    }

    await waitForEnter();
    return true;
}

async function main(): Promise<void> {
    try {
        let running = true;
        while (running) {
            const choice = await showMenu();
            running = await handleMenuChoice(choice);
        }
    } catch (error) {
        if (error instanceof Error && error.message.includes('User force closed')) {
            console.log('\nExiting...\n');
            if (gateway) {
                await gateway.disconnect();
            }
            process.exit(0);
        }
        console.error('\nAn error occurred:', error);
        process.exit(1);
    }
}

main();
