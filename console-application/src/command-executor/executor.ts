import { execSync } from 'child_process';
import * as path from 'path';

const PROJECT_ROOT = path.resolve(__dirname, '../../..');
const CLI_PATH = path.join(PROJECT_ROOT, 'cli', 'tn');

export function executeCommand(command: string): void {
    console.log(`\nExecuting: tn ${command}\n`);
    
    try {
        execSync(`${CLI_PATH} ${command}`, {
            stdio: 'inherit',
            cwd: PROJECT_ROOT
        });
        console.log(`\nCommand completed successfully`);
    } catch (error) {
        console.error(`\nCommand failed`);
    }
}
