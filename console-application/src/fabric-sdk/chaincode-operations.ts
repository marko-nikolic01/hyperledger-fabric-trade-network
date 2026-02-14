import { FabricGateway } from './gateway';

export class ChaincodeOperations {
    private gateway: FabricGateway;

    constructor(gateway: FabricGateway) {
        this.gateway = gateway;
    }

    // ========== MERCHANT OPERATIONS ==========

    async createMerchant(id: string, merchantType: string, taxId: string, accountBalance: number): Promise<any> {
        console.log(`\nCreating merchant ${id}...`);
        
        const result = await this.gateway.submitTransaction(
            'CreateMerchant',
            id,
            merchantType,
            taxId,
            accountBalance.toString()
        );

        const merchant = JSON.parse(result);
        console.log('Merchant created successfully!');
        return merchant;
    }

    // ========== PRODUCT OPERATIONS ==========

    async addProductsToMerchant(merchantId: string, products: any[]): Promise<any> {
        console.log(`\nAdding ${products.length} product(s) to merchant ${merchantId}...`);
        
        const productsJSON = JSON.stringify(products);
        const result = await this.gateway.submitTransaction(
            'AddProductsToMerchant',
            merchantId,
            productsJSON
        );

        const merchant = JSON.parse(result);
        console.log('Products added successfully!');
        return merchant;
    }

    async queryProducts(name: string = '', productId: string = '', merchantType: string = '', maxPrice: number = -1): Promise<any[]> {
        console.log(`\nSearching products...`);
        
        const result = await this.gateway.evaluateTransaction(
            'QueryProducts',
            name,
            productId,
            merchantType,
            maxPrice.toString()
        );

        const products = JSON.parse(result);
        console.log(`Found ${products.length} product(s)`);
        return products;
    }

    // ========== CUSTOMER OPERATIONS ==========

    async createCustomers(customers: any[]): Promise<any[]> {
        console.log(`\nCreating ${customers.length} customer(s)...`);
        
        const customersJSON = JSON.stringify(customers);
        const result = await this.gateway.submitTransaction(
            'AddCustomers',
            customersJSON
        );

        const createdCustomers = JSON.parse(result);
        console.log('Customers created successfully!');
        return createdCustomers;
    }

    // ========== PURCHASE OPERATIONS ==========

    async buyProduct(customerId: string, productId: string): Promise<any> {
        console.log(`\nProcessing purchase: Customer ${customerId} buying Product ${productId}...`);
        
        const result = await this.gateway.submitTransaction(
            'BuyProduct',
            customerId,
            productId
        );

        const purchaseResult = JSON.parse(result);
        console.log('✅ Purchase completed successfully!');
        return purchaseResult;
    }

    // ========== DEPOSIT OPERATIONS ==========

    async depositToMerchant(merchantId: string, amount: number): Promise<any> {
        console.log(`\nDepositing ${amount} to merchant ${merchantId}...`);
        
        const result = await this.gateway.submitTransaction(
            'DepositToMerchant',
            merchantId,
            amount.toString()
        );

        const depositResult = JSON.parse(result);
        console.log('Deposit successful!');
        return depositResult;
    }

    async depositToCustomer(customerId: string, amount: number): Promise<any> {
        console.log(`\nDepositing ${amount} to customer ${customerId}...`);
        
        const result = await this.gateway.submitTransaction(
            'DepositToCustomer',
            customerId,
            amount.toString()
        );

        const depositResult = JSON.parse(result);
        console.log('✅ Deposit successful!');
        return depositResult;
    }
}
