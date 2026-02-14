package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"trading/model"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

func (s *SmartContract) Init(ctx contractapi.TransactionContextInterface) error {
	merchants := []model.Merchant{
		{
			ID:             "M001",
			Type:           model.Supermarket,
			TaxID:          "100000001",
			Products:       []string{"P001", "P002", "P003"},
			Invoices:       []string{},
			AccountBalance: 50000.00,
		},
		{
			ID:             "M002",
			Type:           model.AutoParts,
			TaxID:          "100000002",
			Products:       []string{"P004", "P005"},
			Invoices:       []string{},
			AccountBalance: 75000.00,
		},
		{
			ID:             "M003",
			Type:           model.Electronics,
			TaxID:          "100000003",
			Products:       []string{"P006", "P007"},
			Invoices:       []string{},
			AccountBalance: 100000.00,
		},
	}

	products := []model.Product{
		{ID: "P001", Name: "Bread", ExpirationDate: "2026-01-30", Price: 50.00, Quantity: 100, MerchantID: "M001"},
		{ID: "P002", Name: "Milk", ExpirationDate: "2026-02-05", Price: 120.00, Quantity: 50, MerchantID: "M001"},
		{ID: "P003", Name: "Eggs", ExpirationDate: "2026-02-10", Price: 200.00, Quantity: 30, MerchantID: "M001"},
		{ID: "P004", Name: "Motor Oil", ExpirationDate: "", Price: 1500.00, Quantity: 20, MerchantID: "M002"},
		{ID: "P005", Name: "Air Filter", ExpirationDate: "", Price: 800.00, Quantity: 15, MerchantID: "M002"},
		{ID: "P006", Name: "Laptop", ExpirationDate: "", Price: 80000.00, Quantity: 10, MerchantID: "M003"},
		{ID: "P007", Name: "Phone", ExpirationDate: "", Price: 50000.00, Quantity: 25, MerchantID: "M003"},
	}

	customers := []model.Customer{
		{
			ID:             "C001",
			FirstName:      "John",
			LastName:       "Doe",
			Email:          "john.doe@example.com",
			Invoices:       []string{},
			AccountBalance: 100000.00,
		},
		{
			ID:             "C002",
			FirstName:      "Jane",
			LastName:       "Smith",
			Email:          "jane.smith@example.com",
			Invoices:       []string{},
			AccountBalance: 50000.00,
		},
		{
			ID:             "C003",
			FirstName:      "Bob",
			LastName:       "Johnson",
			Email:          "bob.johnson@example.com",
			Invoices:       []string{},
			AccountBalance: 75000.00,
		},
	}

	for _, merchant := range merchants {
		merchantJSON, err := json.Marshal(merchant)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(merchant.ID, merchantJSON)
		if err != nil {
			return fmt.Errorf("failed to put merchant %s: %v", merchant.ID, err)
		}
	}

	for _, product := range products {
		productJSON, err := json.Marshal(product)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(product.ID, productJSON)
		if err != nil {
			return fmt.Errorf("failed to put product %s: %v", product.ID, err)
		}
	}

	for _, customer := range customers {
		customerJSON, err := json.Marshal(customer)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(customer.ID, customerJSON)
		if err != nil {
			return fmt.Errorf("failed to put customer %s: %v", customer.ID, err)
		}
	}

	return nil
}

func (s *SmartContract) MerchantExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	merchantJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	if merchantJSON == nil {
		return false, nil
	}

	var merchant model.Merchant
	err = json.Unmarshal(merchantJSON, &merchant)
	if err != nil {
		return false, nil
	}

	if merchant.ID == "" || merchant.Type == "" {
		return false, nil
	}

	return merchantJSON != nil, nil
}

func (s *SmartContract) ProductExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	if productJSON == nil {
		return false, nil
	}

	var product model.Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return false, nil
	}

	if product.ID == "" {
		return false, nil
	}

	return productJSON != nil, nil
}

func (s *SmartContract) CustomerExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	customerJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	if customerJSON == nil {
		return false, nil
	}

	var customer model.Customer
	err = json.Unmarshal(customerJSON, &customer)
	if err != nil {
		return false, nil
	}

	if customer.ID == "" || customer.Email == "" {
		return false, nil
	}

	return true, nil
}

func (s *SmartContract) CreateMerchant(ctx contractapi.TransactionContextInterface, id string, merchantType string, taxId string, accountBalance float64) (*model.Merchant, error) {
	exists, err := s.MerchantExists(ctx, id)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, fmt.Errorf("the asset %s already exists", id)
	}

	merchant := model.Merchant{
		ID:             id,
		Type:           model.MerchantType(merchantType),
		TaxID:          taxId,
		Products:       []string{},
		Invoices:       []string{},
		AccountBalance: accountBalance,
	}

	merchantJSON, err := json.Marshal(merchant)
	if err != nil {
		return nil, err
	}

	err = ctx.GetStub().PutState(id, merchantJSON)

	if err != nil {
		return nil, err
	}

	return &merchant, err
}

func (s *SmartContract) GetMerchant(ctx contractapi.TransactionContextInterface, id string) (*model.Merchant, error) {
	merchantJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read merchant %s from world state: %v", id, err)
	}
	if merchantJSON == nil {
		return nil, fmt.Errorf("merchant %s does not exist", id)
	}

	var merchant model.Merchant
	err = json.Unmarshal(merchantJSON, &merchant)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal merchant JSON: %v", err)
	}

	return &merchant, nil
}

func (s *SmartContract) GetCustomer(ctx contractapi.TransactionContextInterface, id string) (*model.Customer, error) {
	exists, err := s.CustomerExists(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to check if customer %s exists: %v", id, err)
	}
	if !exists {
		return nil, fmt.Errorf("customer %s does not exist", id)
	}

	customerJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read customer %s from world state: %v", id, err)
	}

	var customer model.Customer
	err = json.Unmarshal(customerJSON, &customer)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal customer JSON: %v", err)
	}

	return &customer, nil
}

func (s *SmartContract) GetProduct(ctx contractapi.TransactionContextInterface, id string) (*model.Product, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read product %s from world state: %v", id, err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("product %s does not exist", id)
	}

	var product model.Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal product %s: %v", id, err)
	}

	return &product, nil
}

func (s *SmartContract) AddProductsToMerchant(ctx contractapi.TransactionContextInterface, merchantID string, products []model.Product) (*model.Merchant, error) {

	merchant, err := s.GetMerchant(ctx, merchantID)
	if err != nil {
		return nil, err
	}

	for _, product := range products {
		exists, err := s.ProductExists(ctx, product.ID)
		if err != nil {
			return nil, err
		}
		if exists {
			return nil, fmt.Errorf("product %s already exists", product.ID)
		}

		product.MerchantID = merchantID

		productJSON, err := json.Marshal(product)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal product %s: %v", product.ID, err)
		}

		err = ctx.GetStub().PutState(product.ID, productJSON)
		if err != nil {
			return nil, fmt.Errorf("failed to save product %s: %v", product.ID, err)
		}

		merchant.Products = append(merchant.Products, product.ID)
	}

	merchantJSON, err := json.Marshal(merchant)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal merchant: %v", err)
	}

	err = ctx.GetStub().PutState(merchantID, merchantJSON)

	if err != nil {
		return nil, err
	}

	return merchant, err
}

func (s *SmartContract) AddCustomers(ctx contractapi.TransactionContextInterface, customers []model.Customer) ([]model.Customer, error) {

	createdCustomers := []model.Customer{}

	for _, customer := range customers {

		exists, err := s.CustomerExists(ctx, customer.ID)
		if err != nil {
			return []model.Customer{}, err
		}
		if exists {
			return []model.Customer{}, fmt.Errorf("customer %s already exists", customer.ID)
		}

		if customer.Invoices == nil {
			customer.Invoices = []string{}
		}

		customerJSON, err := json.Marshal(customer)
		if err != nil {
			return []model.Customer{}, fmt.Errorf("failed to marshal customer %s: %v", customer.ID, err)
		}

		err = ctx.GetStub().PutState(customer.ID, customerJSON)
		if err != nil {
			return []model.Customer{}, fmt.Errorf("failed to save customer %s: %v", customer.ID, err)
		}

		createdCustomers = append(createdCustomers, customer)
	}

	return createdCustomers, nil
}

func (s *SmartContract) DepositToMerchant(ctx contractapi.TransactionContextInterface, merchantID string, amount float64) (string, error) {
	if amount <= 0 {
		return "", fmt.Errorf("amount must be positive")
	}

	merchant, err := s.GetMerchant(ctx, merchantID)
	if err != nil {
		return "", err
	}

	oldBalance := merchant.AccountBalance
	merchant.AccountBalance += amount
	newBalance := merchant.AccountBalance

	merchantJSON, err := json.Marshal(merchant)
	if err != nil {
		return "", fmt.Errorf("failed to marshal merchant: %v", err)
	}

	err = ctx.GetStub().PutState(merchantID, merchantJSON)
	if err != nil {
		return "", fmt.Errorf("failed to update merchant in world state: %v", err)
	}

	response := map[string]interface{}{
		"id":         merchantID,
		"oldBalance": oldBalance,
		"newBalance": newBalance,
	}

	respJSON, _ := json.Marshal(response)
	return string(respJSON), nil
}

func (s *SmartContract) DepositToCustomer(ctx contractapi.TransactionContextInterface, customerID string, amount float64) (string, error) {
	if amount <= 0 {
		return "", fmt.Errorf("amount must be positive")
	}

	customer, err := s.GetCustomer(ctx, customerID)
	if err != nil {
		return "", err
	}

	oldBalance := customer.AccountBalance
	customer.AccountBalance += amount
	newBalance := customer.AccountBalance

	customerJSON, err := json.Marshal(customer)
	if err != nil {
		return "", fmt.Errorf("failed to marshal customer: %v", err)
	}

	err = ctx.GetStub().PutState(customerID, customerJSON)
	if err != nil {
		return "", fmt.Errorf("failed to update customer in world state: %v", err)
	}

	response := map[string]interface{}{
		"id":         customerID,
		"oldBalance": oldBalance,
		"newBalance": newBalance,
	}

	respJSON, _ := json.Marshal(response)
	return string(respJSON), nil
}

func (s *SmartContract) BuyProduct(ctx contractapi.TransactionContextInterface, customerID string, productID string) (string, error) {

	// Get customer by id
	customer, err := s.GetCustomer(ctx, customerID)
	if err != nil {
		return "", err
	}

	// Get product by id
	product, err := s.GetProduct(ctx, productID)
	if err != nil {
		return "", err
	}

	// Find merchant by product.merchantID
	merchant, err := s.GetMerchant(ctx, product.MerchantID)
	if err != nil {
		return "", err
	}

	// Return if customer doesn't have sufficient funds
	if customer.AccountBalance < product.Price {
		return "", fmt.Errorf("customer %s has insufficient balance", customerID)
	}

	// Update customer and merchant balances
	customerOldBalance := customer.AccountBalance
	merchantOldBalance := merchant.AccountBalance
	customer.AccountBalance -= product.Price
	merchant.AccountBalance += product.Price

	// Invoice
	invoiceID := fmt.Sprintf("INV-%s-%s", customerID, productID)
	customer.Invoices = append(customer.Invoices, invoiceID)
	merchant.Invoices = append(merchant.Invoices, invoiceID)

	// Update product quantity
	product.Quantity -= 1

	// Delete product if quantity 0
	if product.Quantity <= 0 {
		err = ctx.GetStub().DelState(product.ID)
		if err != nil {
			return "", fmt.Errorf("failed to delete product %s: %v", product.ID, err)
		}
	} else {
		productJSON, _ := json.Marshal(product)
		err = ctx.GetStub().PutState(product.ID, productJSON)
		if err != nil {
			return "", fmt.Errorf("failed to update product %s: %v", product.ID, err)
		}
	}

	// Update customer data
	customerJSON, _ := json.Marshal(customer)
	err = ctx.GetStub().PutState(customerID, customerJSON)
	if err != nil {
		return "", fmt.Errorf("failed to update customer %s: %v", customerID, err)
	}

	// Update merchant data
	merchantJSON, _ := json.Marshal(merchant)
	err = ctx.GetStub().PutState(merchant.ID, merchantJSON)
	if err != nil {
		return "", fmt.Errorf("failed to update merchant %s: %v", merchant.ID, err)
	}

	// Return response
	response := map[string]interface{}{
		"customerID":          customerID,
		"merchantID":          merchant.ID,
		"productID":           product.ID,
		"invoiceID":           invoiceID,
		"price":               product.Price,
		"customerOldBalance":  customerOldBalance,
		"customerNewBalance":  customer.AccountBalance,
		"merchantOldBalance":  merchantOldBalance,
		"merchantNewBalance":  merchant.AccountBalance,
		"productRemainingQty": product.Quantity,
	}
	responseJSON, _ := json.Marshal(response)
	return string(responseJSON), nil
}

func (s *SmartContract) QueryProducts(ctx contractapi.TransactionContextInterface, name string, productID string, merchantType string, maxPrice float64) ([]model.Product, error) {
	// Check for every search param, except for merchantType (will be checked for later)
	selector := make(map[string]interface{})
	if name != "" {
		selector["name"] = map[string]string{"$regex": name}
	}
	if productID != "" {
		selector["id"] = productID
	}
	if maxPrice >= 0 {
		selector["price"] = map[string]interface{}{"$lte": maxPrice}
	}

	// If there are no search params, include everything
	if len(selector) == 0 {
		selector["id"] = map[string]string{"$regex": ".*"}
	}

	query := map[string]interface{}{
		"selector": selector,
	}

	queryBytes, err := json.Marshal(query)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal query: %v", err)
	}

	// Query the CouchDB
	resultsIterator, err := ctx.GetStub().GetQueryResult(string(queryBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %v", err)
	}
	defer resultsIterator.Close()

	var filteredProducts []model.Product

	// Check for merchantType separately
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product model.Product
		err = json.Unmarshal(queryResponse.Value, &product)
		if err != nil {
			return nil, err
		}

		if merchantType != "" {
			merchant, err := s.GetMerchant(ctx, product.MerchantID)
			if err != nil {
				return nil, fmt.Errorf("failed to get merchant %s for product %s: %v", product.MerchantID, product.ID, err)
			}

			if string(merchant.Type) != strings.ToUpper(merchantType) {
				continue
			}
		}

		filteredProducts = append(filteredProducts, product)
	}

	return filteredProducts, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating trading chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting trading chaincode: %v\n", err)
	}
}
