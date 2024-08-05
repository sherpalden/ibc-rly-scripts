package prov

type Config struct {
	RPCUrl            string
	NetworkID         int64
	NID               string
	XcallAddress      string
	ConnectionAddress string
	IbcHandler        string
}

func NewConfig() *Config {
	return &Config{
		RPCUrl:     "https://lisbon.net.solidwallet.io/api/v3/",
		NetworkID:  2,
		NID:        "0x2.icon",
		IbcHandler: "cx27d5d8af883b7f0a69377e4cb05648adff6f695b",
	}
}
