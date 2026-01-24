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
