require("hardhat-deploy")
require("hardhat-deploy-ethers")

const { networkConfig } = require("../helper-hardhat-config")

const private_key = network.config.accounts[0]
const wallet = new ethers.Wallet(private_key, ethers.provider)

module.exports = async ({ deployments }) => {
    console.log("Wallet Ethereum Address:", wallet.address)
    const chainId = network.config.chainId

    //deploy TimePact
    const TimePact = await ethers.getContractFactory("TimePact", wallet)
    console.log("Deploying TimePact...")
    const timePact = await TimePact.deploy()
    await timePact.deployed()
    console.log("TimePact deployed to:", timePact.address)
}