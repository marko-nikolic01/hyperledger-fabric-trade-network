#!/usr/bin/env node
import { MenuOption, showMenu, waitForEnter } from './console-management/menu';
import { confirmSensitiveOperation, getCommandForOption } from './console-management/menu-commands';
import { executeCommand } from './command-executor/executor';

async function handleMenuChoice(choice: MenuOption): Promise<boolean> {
    if (choice === MenuOption.EXIT) {
        console.log('\nExiting...\n');
        return false;
    }

    if (choice === MenuOption.DEPLOY_CHAINCODE || choice === MenuOption.RUN_APPLICATION) {
        console.log('\nThis feature is coming soon...');
        await waitForEnter();
        return true;
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
        await waitForEnter();
    }

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
