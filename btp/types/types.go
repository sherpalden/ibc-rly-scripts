package types

import (
	goloopClient "github.com/icon-project/goloop/client"
	"github.com/icon-project/goloop/module"
	"github.com/icon-project/goloop/server/jsonrpc"
)

const (
	EmitMessageEvent = "Message(str,int,bytes)"
	CallMessageEvent = "CallMessage(str,str,int,int,bytes)"

	WsBlockConnPath = "/block"
	WsBlockConnKey  = WsBlockConnPath

	WsEventConnPath = "/event"
	WsEventConnKey  = WsEventConnPath

	WsBtpConnPath = "/btp"
	WsBtpConnKey  = "/btp"
)

var (
	XcallEvents      = []string{CallMessageEvent}
	ConnectionEvents = []string{EmitMessageEvent}
)

type Block struct {
	Height    int64 `json:"height"`
	Timestamp int64 `json:"time_stamp"`
}

type BlockNotification struct {
	goloopClient.BlockNotification
	Error error
}

type EventNotification struct {
	goloopClient.EventNotification
	Error error
}

type EventFilter struct {
	ScoreAddr string    `json:"addr,omitempty"`
	Signature string    `json:"event"`             //Method signature of event
	Indexed   []*string `json:"indexed,omitempty"` //Array of arguments to match with indexed parameters of event. null matches any value.
	Data      []*string `json:"data,omitempty"`    //Array of arguments to match with not indexed parameters of event. null matches any value. If indexed parameters of event exists, require 'indexed' parameter
}

type CallData struct {
	Method string      `json:"method"`
	Params interface{} `json:"params,omitempty"`
}

type CallArgs struct {
	ScoreAddress jsonrpc.Address
	Method       string
	Params       interface{}
}

type RecvMessageArgs struct {
	SrcNetwork string           `json:"srcNetwork"`
	ConnSn     jsonrpc.HexInt   `json:"_connSn"`
	Msg        jsonrpc.HexBytes `json:"msg"`
}

type ExecuteCallArgs struct {
	ReqID jsonrpc.HexInt   `json:"_reqId"`
	Data  jsonrpc.HexBytes `json:"_data"`
}

type BtpBlockHeader struct {
	MainHeight             int64
	Round                  int32
	NextProofContextHash   []byte
	NetworkSectionToRoot   []module.MerkleNode
	NetworkID              int64
	UpdateNumber           int64
	PrevNetworkSectionHash []byte
	MessageCount           int64
	MessagesRoot           []byte
	NextProofContext       []byte
}
