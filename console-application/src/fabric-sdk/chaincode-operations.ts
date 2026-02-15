import { FabricGateway } from './gateway';

export class ChaincodeOperations {
    private async withGateway<T>(
        orgName: string,
        channelName: string,
        identityLabel: string,
        action: (gateway: FabricGateway) => Promise<T>
    ): Promise<T> {
        const gateway = new FabricGateway();
        try {
            await gateway.connect(orgName, channelName, identityLabel);
            return await action(gateway);
        } finally {
            await gateway.disconnect();
        }
    }

    async createMerchant(orgName: string, channelName: string, identityLabel: string, id: string, merchantType: string, taxId: string, accountBalance: number): Promise<any> {
        console.log(`\nCreating merchant ${id}...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const result = await gateway.submitTransaction(
                'CreateMerchant',
                id,
                merchantType,
                taxId,
                accountBalance.toString()
            );

            const merchant = JSON.parse(result);
            console.log('Merchant created successfully!');
            return merchant;
        });
    }

    async addProductsToMerchant(orgName: string, channelName: string, identityLabel: string, merchantId: string, products: any[]): Promise<any> {
        console.log(`\nAdding ${products.length} product(s) to merchant ${merchantId}...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const productsJSON = JSON.stringify(products);
            const result = await gateway.submitTransaction(
                'AddProductsToMerchant',
                merchantId,
                productsJSON
            );

            const merchant = JSON.parse(result);
            console.log('Products added successfully!');
            return merchant;
        });
    }

    async queryProducts(orgName: string, channelName: string, identityLabel: string, name: string = '', productId: string = '', merchantType: string = '', maxPrice: number = -1): Promise<any[]> {
        console.log(`\nSearching products...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const result = await gateway.evaluateTransaction(
                'QueryProducts',
                name,
                productId,
                merchantType,
                maxPrice.toString()
            );

            const products = JSON.parse(result);
            console.log(`Found ${products.length} product(s)`);
            return products;
        });
    }

    async createCustomers(orgName: string, channelName: string, identityLabel: string, customers: any[]): Promise<any[]> {
        console.log(`\nCreating ${customers.length} customer(s)...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const customersJSON = JSON.stringify(customers);
            const result = await gateway.submitTransaction(
                'AddCustomers',
                customersJSON
            );

            const createdCustomers = JSON.parse(result);
            console.log('Customers created successfully!');
            return createdCustomers;
        });
    }

    async buyProduct(orgName: string, channelName: string, identityLabel: string, customerId: string, productId: string): Promise<any> {
        console.log(`\nProcessing purchase: Customer ${customerId} buying Product ${productId}...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const result = await gateway.submitTransaction(
                'BuyProduct',
                customerId,
                productId
            );

            const purchaseResult = JSON.parse(result);
            console.log('Purchase completed successfully!');
            return purchaseResult;
        });
    }

    async depositToMerchant(orgName: string, channelName: string, identityLabel: string, merchantId: string, amount: number): Promise<any> {
        console.log(`\nDepositing ${amount} to merchant ${merchantId}...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const result = await gateway.submitTransaction(
                'DepositToMerchant',
                merchantId,
                amount.toString()
            );

            const depositResult = JSON.parse(result);
            console.log('Deposit successful!');
            return depositResult;
        });
    }

    async depositToCustomer(orgName: string, channelName: string, identityLabel: string, customerId: string, amount: number): Promise<any> {
        console.log(`\nDepositing ${amount} to customer ${customerId}...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const result = await gateway.submitTransaction(
                'DepositToCustomer',
                customerId,
                amount.toString()
            );

            const depositResult = JSON.parse(result);
            console.log('Deposit successful!');
            return depositResult;
        });
    }

    async merchantExists(orgName: string, channelName: string, identityLabel: string, merchantId: string): Promise<boolean> {
        console.log(`\nChecking merchant ${merchantId}...`);

        return this.withGateway(orgName, channelName, identityLabel, async (gateway) => {
            const result = await gateway.evaluateTransaction(
                'MerchantExists',
                merchantId
            );

            const exists = JSON.parse(result);
            console.log(`Merchant exists: ${exists}`);
            return Boolean(exists);
        });
    }
}
