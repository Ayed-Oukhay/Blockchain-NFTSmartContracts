/*-----------we will use this file to interact with the Flow JS SDK------------*/
/*This configuration file just helps the JS SDK work with the Flow blockchain (or emulator in this case).*/
import {config} from "@onflow/fcl"
config()
.put("accessNode.api", process.env.REACT_APP_ACCESS_NODE) 
.put("challenge.handshake", process.env.REACT_APP_WALLET_DISCOVERY) 
.put("0xProfile", process.env.REACT_APP_CONTRACT_PROFILE)