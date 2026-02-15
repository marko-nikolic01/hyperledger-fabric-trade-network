import inquirer from 'inquirer';
import { MenuOption } from './menu';

const commandMap: Record<string, string> = {
    [MenuOption.START_NETWORK]: 'up',
    [MenuOption.STOP_NETWORK]: 'down',
    [MenuOption.CLEAN_NETWORK]: 'clean',
    [MenuOption.CHECK_STATUS]: 'check',
    [MenuOption.CREATE_CHANNELS]: 'createchannels',
    [MenuOption.DEPLOY_CHAINCODE]: 'deploycc',
    [MenuOption.HELP]: 'help'
};

const sdkOperations = [
    MenuOption.LOGIN,
    MenuOption.ENROLL_CA_USER,
    MenuOption.CREATE_MERCHANT,
    MenuOption.ADD_PRODUCTS,
    MenuOption.CREATE_CUSTOMERS,
    MenuOption.BUY_PRODUCTS,
    MenuOption.DEPOSIT_TO_MERCHANT,
    MenuOption.DEPOSIT_TO_CUSTOMER,
    MenuOption.QUERY_PRODUCTS,
]

export async function confirmSensitiveOperation(operation: string, warning: string): Promise<boolean> {
    const { confirmed } = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'confirmed',
            message: `${warning} Are you sure you want to ${operation}?`,
            default: false
        }
    ]);
    return confirmed;
}

export function getCommandForOption(option: MenuOption): string | undefined {
    
    if (sdkOperations.includes(option)) {
        return undefined;
    }

    return commandMap[option] || undefined;
}
