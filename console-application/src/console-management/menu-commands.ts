import inquirer from 'inquirer';
import { MenuOption } from './menu';

const commandMap: Record<string, string> = {
    [MenuOption.START_NETWORK]: 'up',
    [MenuOption.STOP_NETWORK]: 'down',
    [MenuOption.CLEAN_NETWORK]: 'clean',
    [MenuOption.CHECK_STATUS]: 'check',
    [MenuOption.CREATE_CHANNELS]: 'createchannels',
    [MenuOption.HELP]: 'help'
};

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
    return commandMap[option];
}
