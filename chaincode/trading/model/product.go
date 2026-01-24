package model

type Product struct {
	ID             string  `json:"id"`
	Name           string  `json:"name"`
	ExpirationDate string  `json:"expirationDate"`
	Price          float64 `json:"price"`
	Quantity       int     `json:"quantity"`
	MerchantID     string  `json:"merchantId"`
}
