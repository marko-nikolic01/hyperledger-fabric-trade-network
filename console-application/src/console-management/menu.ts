import inquirer from 'inquirer';

export enum MenuOption {
    START_NETWORK = 'Start Network (tn up)',
    STOP_NETWORK = 'Stop Network (tn down)',
    CLEAN_NETWORK = 'Clean Network (tn clean)',
    CHECK_STATUS = 'Check Status (tn check)',
    CREATE_CHANNELS = 'Create Channels (tn createchannels)',
    DEPLOY_CHAINCODE = 'Deploy Chaincode (tn deploy) [Coming soon]',
    RUN_APPLICATION = 'Run Application (tn app) [Coming soon]',
    HELP = 'Help (tn help)',
    EXIT = 'Exit'
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
                new inquirer.Separator('--- Application ---'),
                MenuOption.RUN_APPLICATION,
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
