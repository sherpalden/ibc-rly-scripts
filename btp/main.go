package main

import (
	"context"

	"github.com/sherpalden/icon-btp/prov"
	"go.uber.org/zap"
)

func main() {
	cfg := prov.NewConfig()
	logger, err := zap.NewDevelopment()
	if err != nil {
		panic(err)
	}
	p := prov.NewProvider(logger, cfg)

	//41783281
	if err := p.StartBtpListener(context.Background(), 41783200); err != nil {
		logger.Error("failed to start btp listener", zap.Error(err))
	}

	// btpIinfo, err := p.Clv3.GetBTPNetworkInfo(&v3.BTPQueryParam{Id: jsonrpc.HexIntFromInt64(2)})
	// if err != nil {
	// 	logger.Error("failed to get btp network info", zap.Error(err))
	// }

	// fmt.Printf("\n Btp Net Info: %+v \n", btpIinfo)
	// 28192481
	//cx27d5d8af883b7f0a69377e4cb05648adff6f695b

	// if err := p.FindBtpBlock(context.Background(), 41783281-1); err != nil {
	// 	logger.Error("failed to find btp block", zap.Error(err))
	// }
	// h, err := p.GetBtpHeader(41783281)
	// if err == nil {
	// 	fmt.Printf("\nWoeo this is a btp block: %+v\n", h)
	// } else {
	// 	fmt.Println("Shit this is not a btp block: ", err.Error())
	// }
}
