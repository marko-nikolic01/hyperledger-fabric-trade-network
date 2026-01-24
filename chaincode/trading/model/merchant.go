package model

type MerchantType string

const (
	Supermarket  MerchantType = "SUPERMARKET"
	AutoParts    MerchantType = "AUTO_PARTS"
	Electronics  MerchantType = "ELECTRONICS"
	Bookstore    MerchantType = "BOOKSTORE"
	Pharmacy     MerchantType = "PHARMACY"
)

type Merchant struct {
	ID             string       `json:"id"`
	Type           MerchantType `json:"type"`
	TaxID          string       `json:"taxId"`
	Products       []string     `json:"products"`
	Invoices       []string     `json:"invoices"`
	AccountBalance float64      `json:"accountBalance"`
}
