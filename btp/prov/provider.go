package prov

import (
	"context"
	"encoding/base64"
	"sync"

	goloopClient "github.com/icon-project/goloop/client"
	"github.com/icon-project/goloop/common"
	"github.com/icon-project/goloop/common/codec"
	"github.com/icon-project/goloop/server"
	"github.com/icon-project/goloop/server/jsonrpc"
	v3 "github.com/icon-project/goloop/server/v3"
	"github.com/sherpalden/icon-btp/types"
	"go.uber.org/zap"
)

type Provider struct {
	log  *zap.Logger
	cfg  *Config
	Clv3 goloopClient.ClientV3
}

func NewProvider(
	log *zap.Logger,
	cfg *Config,
) *Provider {
	clv3 := goloopClient.NewClientV3(cfg.RPCUrl)
	return &Provider{
		log, cfg, *clv3,
	}
}

func (p Provider) StartBtpListener(ctx context.Context, startHeight int64) error {
	btpreq := server.BTPRequest{
		Height:    common.HexInt64{Value: startHeight},
		NetworkId: common.HexInt64{Value: 2},
		ProofFlag: common.HexBool{Value: true},
	}

	cancelCh := make(chan bool)
	defer func() {
		cancelCh <- true
	}()

	btpStream := make(chan server.BTPNotification)

	if err := p.Clv3.MonitorBtp(&btpreq,
		func(v *server.BTPNotification) {
			btpStream <- *v
		},
		cancelCh,
	); err != nil {
		p.log.Error("failed to monitor btp block", zap.Error(err))
	}

	p.log.Info("Started btp listener", zap.Int64("start-height", startHeight))

	for btp := range btpStream {
		headerBytes, err := base64.StdEncoding.DecodeString(btp.Header)
		if err != nil {
			p.log.Error("failed to decode btp header string", zap.Error(err))
			break
		}
		var btpHeader types.BtpBlockHeader
		if _, err := codec.UnmarshalFromBytes(headerBytes, &btpHeader); err != nil {
			p.log.Error("failed to unmarshal btp header", zap.Error(err))
		}

		p.log.Info("Got btp header",
			zap.Int64("main-height", btpHeader.MainHeight),
			zap.Int64("round", int64(btpHeader.Round)),

			zap.Int64("network-id", btpHeader.NetworkID),
			zap.Int64("update-number", btpHeader.UpdateNumber),
			zap.Int64("message-count", btpHeader.MessageCount),
		)
	}
	return nil
}

func (p Provider) StartEventListener(ctx context.Context, startHeight int64) error {
	// adrr, err := common.NewAddressFromString(p.cfg.IbcHandler)
	// if err != nil {
	// 	return err
	// }

	eventreq := server.EventRequest{
		Height: common.HexInt64{Value: startHeight},
		Logs:   common.HexBool{Value: true},
		Filters: []*server.EventFilter{
			{
				// Addr:      adrr,
				Signature: "RecvPacket(bytes)",
			},
		},
	}

	cancelCh := make(chan bool)
	defer func() {
		cancelCh <- true
	}()

	eventStream := make(chan *goloopClient.EventNotification)

	if err := p.Clv3.MonitorEvent(&eventreq,
		func(v *goloopClient.EventNotification) {
			eventStream <- v
		},
		cancelCh,
	); err != nil {
		p.log.Error("failed to monitor events", zap.Error(err))
	}

	p.log.Info("Started event listener", zap.Int64("start-height", startHeight))

	for event := range eventStream {
		btpHeight := event.Height.Value() - 1
		btpHeader, err := p.GetBtpHeader(btpHeight)
		if err != nil {
			p.log.Info("failed to get btp header", zap.Int64("height", btpHeight), zap.Error(err))
			continue
		}
		p.log.Info("Got btp header",
			zap.Int64("main-height", btpHeader.MainHeight),
			zap.Int64("round", int64(btpHeader.Round)),

			zap.Int64("network-id", btpHeader.NetworkID),
			zap.Int64("update-number", btpHeader.UpdateNumber),
			zap.Int64("message-count", btpHeader.MessageCount),
		)
	}
	return nil
}

func (p Provider) GetBtpHeader(btpHeight int64) (*types.BtpBlockHeader, error) {
	param := &v3.BTPMessagesParam{
		Height:    jsonrpc.HexIntFromInt64(btpHeight),
		NetworkId: jsonrpc.HexIntFromInt64(p.cfg.NetworkID),
	}
	btpHeaderStr, err := p.Clv3.GetBTPHeader(param)
	if err != nil {
		return nil, err
	}

	headerBytes, err := base64.StdEncoding.DecodeString(btpHeaderStr)
	if err != nil {
		return nil, err
	}
	var btpHeader types.BtpBlockHeader
	if _, err := codec.UnmarshalFromBytes(headerBytes, &btpHeader); err != nil {
		return nil, err
	}

	return &btpHeader, nil
}

func (p Provider) FindBtpBlock(ctx context.Context, startHeight int64) error {
	lastBlock, err := p.Clv3.GetLastBlock()
	if err != nil {
		return err
	}

	btpBlockStream := make(chan int64)

	wg := &sync.WaitGroup{}
	for i := startHeight; i <= lastBlock.Height; i++ {
		wg.Add(1)
		btpHeight := i
		go func() {
			defer wg.Done()
			btpHeader, err := p.GetBtpHeader(btpHeight)
			if err == nil {
				btpBlockStream <- btpHeader.MainHeight
			}
		}()
	}

	go func() {
		wg.Wait()
		close(btpBlockStream)
	}()

	for btpBlock := range btpBlockStream {
		p.log.Info("Found btp block", zap.Int64("height", btpBlock))
	}

	return nil
}
