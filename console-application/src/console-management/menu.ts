import inquirer from 'inquirer';

export enum MenuOption {
    // Network management
    START_NETWORK = 'Start Network (tn up)',
    STOP_NETWORK = 'Stop Network (tn down)',
    CLEAN_NETWORK = 'Clean Network (tn clean)',
    CHECK_STATUS = 'Check Status (tn check)',

    // Channel management
    CREATE_CHANNELS = 'Create Channels (tn createchannels)',

    // Chaincode management
    DEPLOY_CHAINCODE = 'Deploy Chaincode (tn deploycc)',
    
    // Login
    REGISTER = 'Register',
    LOGIN = 'Login',
    
    // Functionalities
    CREATE_MERCHANT = 'Create merchant',
    ADD_PRODUCTS = 'Add products to merchant',
    CREATE_CUSTOMERS = 'Create customers',
    BUY_PRODUCTS = 'Buy products',
    DEPOSIT_TO_MERCHANT = 'Deposit to merchant',
    DEPOSIT_TO_CUSTOMER = 'Deposit to customer',
    QUERY_PRODUCTS = 'Search Products (Query)',

    // Other
    HELP = 'Help (tn help)',
    EXIT = 'Exit',
}

export function displayHeader(): void {
    console.clear();
    console.log('\n  Hyperledger Fabric Trade Network\n');
}

export async function showMenu(): Promise<MenuOption> {
    displayHeader();

    const { choice } = await inquirer.prompt([
        {
            type: 'list',
            name: 'choice',
            message: 'Select an option:',
            choices: [
                new inquirer.Separator('--- Network Management ---'),
                MenuOption.START_NETWORK,
                MenuOption.STOP_NETWORK,
                MenuOption.CLEAN_NETWORK,
                MenuOption.CHECK_STATUS,

                new inquirer.Separator('--- Channel Management ---'),
                MenuOption.CREATE_CHANNELS,

                new inquirer.Separator('--- Chaincode Management ---'),
                MenuOption.DEPLOY_CHAINCODE,

                // new inquirer.Separator('--- Register/login ---'),
                // MenuOption.REGISTER,
                // MenuOption.LOGIN,

                new inquirer.Separator('--- Functionalities ---'),
                MenuOption.CREATE_MERCHANT,
                MenuOption.ADD_PRODUCTS,
                MenuOption.CREATE_CUSTOMERS,
                MenuOption.BUY_PRODUCTS,
                MenuOption.DEPOSIT_TO_MERCHANT,
                MenuOption.DEPOSIT_TO_CUSTOMER,
                MenuOption.QUERY_PRODUCTS,

                new inquirer.Separator('--- Other ---'),
                MenuOption.HELP,
                MenuOption.EXIT
            ]
        }
    ]);

    return choice;
}

export async function waitForEnter(): Promise<void> {
    await inquirer.prompt([
        {
            type: 'input',
            name: 'continue',
            message: 'Press Enter to continue...',
        }
    ]);
}

// HELPER FUNCTIONS

// Helper function for ID input
export async function promptForId(entityType: string): Promise<string> {
    const { id } = await inquirer.prompt([
        {
            type: 'input',
            name: 'id',
            message: `Enter ${entityType} ID:`,
            validate: (input: string) => {
                if (!input.trim()) {
                    return `${entityType} ID cannot be empty`;
                }
                return true;
            }
        }
    ]);
    return id.trim();
}

// Helper function for merchant data input
export async function promptMerchantData() {
    return await inquirer.prompt([
        {
            type: 'input',
            name: 'id',
            message: 'Merchant ID:',
            validate: (input: string) => input.trim() ? true : 'ID is required'
        },
        {
            type: 'list',
            name: 'type',
            message: 'Merchant Type:',
            choices: ['SUPERMARKET', 'AUTOPARTS', 'ELECTRONICS', 'PHARMACY', 'BOOKSTORE']
        },
        {
            type: 'input',
            name: 'taxId',
            message: 'Tax ID (PIB):',
            validate: (input: string) => input.trim() ? true : 'Tax ID is required'
        },
        {
            type: 'number',
            name: 'accountBalance',
            message: 'Initial Account Balance:',
            default: 0,
            validate: (input: number) => input >= 0 ? true : 'Balance must be non-negative'
        }
    ]);
}

// Helper product data input
export async function promptProductData() {
    return await inquirer.prompt([
        {
            type: 'input',
            name: 'id',
            message: 'Product ID:',
            validate: (input: string) => input.trim() ? true : 'ID is required'
        },
        {
            type: 'input',
            name: 'name',
            message: 'Product Name:',
            validate: (input: string) => input.trim() ? true : 'Name is required'
        },
        {
            type: 'number',
            name: 'price',
            message: 'Price:',
            validate: (input: number) => input > 0 ? true : 'Price must be positive'
        },
        {
            type: 'number',
            name: 'quantity',
            message: 'Quantity:',
            validate: (input: number) => input >= 0 ? true : 'Quantity must be non-negative'
        },
        {
            type: 'input',
            name: 'expirationDate',
            message: 'Expiration Date (YYYY-MM-DD or leave empty):',
            default: ''
        },
        {
            type: 'input',
            name: 'merchantId',
            message: 'Merchant ID:',
            validate: (input: string) => input.trim() ? true : 'Merchant ID is required'
        }
    ]);
}

// Helper for customer data input
export async function promptCustomerData() {
    return await inquirer.prompt([
        {
            type: 'input',
            name: 'id',
            message: 'Customer ID:',
            validate: (input: string) => input.trim() ? true : 'ID is required'
        },
        {
            type: 'input',
            name: 'firstName',
            message: 'First Name:',
            validate: (input: string) => input.trim() ? true : 'First name is required'
        },
        {
            type: 'input',
            name: 'lastName',
            message: 'Last Name:',
            validate: (input: string) => input.trim() ? true : 'Last name is required'
        },
        {
            type: 'input',
            name: 'email',
            message: 'Email:',
            validate: (input: string) => {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                return emailRegex.test(input) ? true : 'Invalid email format';
            }
        },
        {
            type: 'number',
            name: 'accountBalance',
            message: 'Initial Account Balance:',
            default: 0,
            validate: (input: number) => input >= 0 ? true : 'Balance must be non-negative'
        }
    ]);
}

// Helper function for querying products
export async function promptProductSearch() {
    return await inquirer.prompt([
        {
            type: 'input',
            name: 'name',
            message: 'Product Name (leave empty to skip):',
            default: ''
        },
        {
            type: 'input',
            name: 'productId',
            message: 'Product ID (leave empty to skip):',
            default: ''
        },
        {
            type: 'input',
            name: 'merchantType',
            message: 'Merchant Type (leave empty to skip):',
            default: ''
        },
        {
            type: 'number',
            name: 'maxPrice',
            message: 'Max Price (0 or negative to skip):',
            default: -1
        }
    ]);
}

// Helper function for depositing money
export async function promptDepositData(entityType: 'merchant' | 'customer') {
    return await inquirer.prompt([
        {
            type: 'input',
            name: 'id',
            message: `${entityType === 'merchant' ? 'Merchant' : 'Customer'} ID:`,
            validate: (input: string) => input.trim() ? true : 'ID is required'
        },
        {
            type: 'number',
            name: 'amount',
            message: 'Amount to deposit:',
            validate: (input: number) => input > 0 ? true : 'Amount must be positive'
        }
    ]);
}