package model

type Invoice struct {
	ID         string  `json:"id"`
	MerchantID string  `json:"merchantId"`
	CustomerID string  `json:"customerId"`
	ProductID  string  `json:"productId"`
	Price      float64 `json:"price"`
	Quantity   int     `json:"quantity"`
	Date       string  `json:"date"`
}
