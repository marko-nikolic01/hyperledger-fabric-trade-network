#!/usr/bin/env node
import { MenuOption, promptCustomerData, promptDepositData, promptMerchantData, promptProductData, promptProductSearch, showMenu, waitForEnter } from './console-management/menu';
import { confirmSensitiveOperation, getCommandForOption } from './console-management/menu-commands';
import { executeCommand } from './command-executor/executor';
import { FabricCAClient } from './fabric-sdk/ca-client';
import { ChaincodeOperations } from './fabric-sdk/chaincode-operations';
import { Wallets } from 'fabric-network';

const chaincodeOps = new ChaincodeOperations();
const defaultChannel = 'tradechannel1';
let currentOrg: string | null = null;
let currentIdentityLabel: string | null = null;

function ensureIdentitySelected(): { orgName: string; identityLabel: string } {
    if (!currentOrg || !currentIdentityLabel) {
        throw new Error('No identity selected. Use "Login (select identity)" first.');
    }
    return {
        orgName: currentOrg,
        identityLabel: currentIdentityLabel
    };
}

async function handleLogin(): Promise<void> {
    const walletPath = `${process.cwd()}/wallet`;
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    const identities = await wallet.list();

    if (identities.length === 0) {
        console.log('\nNo identities in wallet. Enroll a user first.');
        return;
    }

    const inquirer = (await import('inquirer')).default;
    const { label } = await inquirer.prompt([
        {
            type: 'list',
            name: 'label',
            message: 'Select identity:',
            choices: identities
        }
    ]);

    const orgMatch = /@([^\.]+)\.trade\.com$/i.exec(label);
    const orgName = orgMatch ? orgMatch[1] : '';

    if (!orgName) {
        throw new Error('Selected identity does not include org in label (expected user@orgX.trade.com).');
    }

    currentOrg = orgName;
    currentIdentityLabel = label;
    console.log(`\nLogged in as ${label} (org: ${orgName}).`);
}

async function handleSDKOperation(choice: MenuOption): Promise<void> {
    try {
        if (choice === MenuOption.LOGIN) {
            await handleLogin();
            return;
        }
        if (choice === MenuOption.ENROLL_CA_USER) {
            const inquirer = (await import('inquirer')).default;
            const { orgName, userId, userSecret } = await inquirer.prompt([
                {
                    type: 'list',
                    name: 'orgName',
                    message: 'Select organization:',
                    choices: ['org1', 'org2', 'org3']
                },
                {
                    type: 'input',
                    name: 'userId',
                    message: 'User ID:'
                },
                {
                    type: 'password',
                    name: 'userSecret',
                    message: 'User Secret (password):',
                    mask: '*'
                }
            ]);

            const caClient = new FabricCAClient();
            await caClient.registerAndEnrollUser({
                orgName,
                userId: userId.trim(),
                userSecret: userSecret.trim()
            });
            console.log(`\nUser ${userId} enrolled and added to wallet.`);
            return;
        }

        const { orgName, identityLabel } = ensureIdentitySelected();

        switch (choice) {
            case MenuOption.CREATE_MERCHANT: {
                const data = await promptMerchantData();
                const result = await chaincodeOps.createMerchant(
                    orgName,
                    defaultChannel,
                    identityLabel,
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
                const result = await chaincodeOps.addProductsToMerchant(
                    orgName,
                    defaultChannel,
                    identityLabel,
                    productData.merchantId,
                    products
                );
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
                const result = await chaincodeOps.createCustomers(
                    orgName,
                    defaultChannel,
                    identityLabel,
                    customers
                );
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.BUY_PRODUCTS: {
                const customerId = await promptForId('Customer');
                const productId = await promptForId('Product');
                const result = await chaincodeOps.buyProduct(
                    orgName,
                    defaultChannel,
                    identityLabel,
                    customerId,
                    productId
                );
                console.log('\nPurchase Result:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.DEPOSIT_TO_MERCHANT: {
                const data = await promptDepositData('merchant');
                const result = await chaincodeOps.depositToMerchant(
                    orgName,
                    defaultChannel,
                    identityLabel,
                    data.id,
                    data.amount
                );
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.DEPOSIT_TO_CUSTOMER: {
                const data = await promptDepositData('customer');
                const result = await chaincodeOps.depositToCustomer(
                    orgName,
                    defaultChannel,
                    identityLabel,
                    data.id,
                    data.amount
                );
                console.log('\nResult:');
                console.log(JSON.stringify(result, null, 2));
                break;
            }

            case MenuOption.QUERY_PRODUCTS: {
                const searchParams = await promptProductSearch();
                const results = await chaincodeOps.queryProducts(
                    orgName,
                    defaultChannel,
                    identityLabel,
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
            process.exit(0);
        }
        console.error('\nAn error occurred:', error);
        process.exit(1);
    }
}

main();
