package main

import (
	"bytes"
	"fmt"
	"os/exec"
	"strconv"
	"sync"
)

func sendMsgIconToArchway() error {
	cmd := exec.Command("sh", "icon.sh", "send-message", "ARCHWAY")
	var out bytes.Buffer
	cmd.Stderr = &out
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf(out.String())
	} else {
		fmt.Println(out.String())
		return nil
	}
}

func sendMsgArchwayToIcon(from string) error {
	cmd := exec.Command("sh", "wasm.sh", "send-message-icon", "ARCHWAY", from)
	var out bytes.Buffer
	cmd.Stderr = &out
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf(out.String())
	} else {
		fmt.Println(out.String())
	}
	return nil
}

func tranferTokenIconToCentauri(toUser string) error {
	cmd := exec.Command("sh", "icon.sh", "transfer-token", "ARCHWAY", toUser)
	var out bytes.Buffer
	cmd.Stderr = &out
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf(out.String())
	} else {
		fmt.Println(out.String())
		return nil
	}
}

func tranferTokenCentauriToIcon(fromUser string) error {
	cmd := exec.Command("sh", "wasm.sh", "transfer_token_icon", fromUser)
	var out bytes.Buffer
	cmd.Stderr = &out
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf(out.String())
	} else {
		fmt.Println(out.String())
		return nil
	}
}

func getResStream() <-chan string {
	resStream := make(chan string)

	wg := &sync.WaitGroup{}

	for i := 1; i <= 1; i++ {
		wg.Add(1)

		// go func(wg *sync.WaitGroup) {
		// 	defer wg.Done()
		// 	err := sendMsgIconToArchway()
		// 	msg := fmt.Sprintf("msg icon -> archway")
		// 	if err != nil {
		// 		msg = fmt.Sprintf("%s failed: %s", msg, err.Error())
		// 	} else {
		// 		msg = fmt.Sprintf("%s success", msg)
		// 	}
		// 	resStream <- msg
		// }(wg)

		// go func(wg *sync.WaitGroup, pos int) {
		// 	defer wg.Done()
		// 	err := sendMsgArchwayToIcon("user" + strconv.Itoa(pos))
		// 	msg := fmt.Sprintf("msg archway -> icon")
		// 	if err != nil {
		// 		msg = fmt.Sprintf("%s failed: %s", msg, err.Error())
		// 	} else {
		// 		msg = fmt.Sprintf("%s success", msg)
		// 	}
		// 	resStream <- msg
		// }(wg, i)

		go func(wg *sync.WaitGroup, pos int) {
			defer wg.Done()
			err := tranferTokenIconToCentauri("user" + strconv.Itoa(pos))
			msg := fmt.Sprintf("token icon -> centauri")
			if err != nil {
				msg = fmt.Sprintf("%s failed: %s", msg, err.Error())
			} else {
				msg = fmt.Sprintf("%s success", msg)
			}
			resStream <- msg
		}(wg, i)

		// go func(wg *sync.WaitGroup, pos int) {
		// 	defer wg.Done()
		// 	err := tranferTokenCentauriToIcon("user" + strconv.Itoa(pos))
		// 	msg := fmt.Sprintf("token centauri -> icon")
		// 	if err != nil {
		// 		msg = fmt.Sprintf("%s failed: %s", msg, err.Error())
		// 	} else {
		// 		msg = fmt.Sprintf("%s success", msg)
		// 	}
		// 	resStream <- msg
		// }(wg, i)
	}

	go func() {
		wg.Wait()
		close(resStream)
	}()

	return resStream
}

func main() {
	fmt.Println("Stress Testing Intialized")
	var counter int
	for res := range getResStream() {
		fmt.Println("----------------------------------------")
		fmt.Println(strconv.Itoa(counter+1) + " : " + res)
		counter++
	}
}
