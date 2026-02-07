package main

import (
	"encoding/json"
	"fmt"
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
