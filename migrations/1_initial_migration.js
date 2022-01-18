const HenHouseRouter = artifacts.require('HenHouseRouter')
const HenHouseToken = artifacts.require('HenHouse')
const HenHouseEggToken = artifacts.require('EggToken')

module.exports = async function (deployer) {
    let routerAddress = "";
    let henhAddress = "";
    let eggAddress = "";
    let token, router, egg

    let teamWallet = deployer.networks.development.from;
    let rewardsWallet = deployer.networks.development.from;
    let stakingWallet = deployer.networks.development.from;
    let reserveWallet = deployer.networks.development.from;
    let sponsorsWallet = deployer.networks.development.from;
    let airdropWallet = deployer.networks.development.from;


    await Promise.all([
        deployer.deploy(HenHouseRouter).then(() => routerAddress = HenHouseRouter.address).then(() =>
            deployer.deploy(HenHouseToken, "HenHouse Token", "HENH", routerAddress, teamWallet, rewardsWallet, stakingWallet, reserveWallet, sponsorsWallet, airdropWallet).then(() => henhAddress = HenHouseToken.address).then(() =>
                deployer.deploy(HenHouseEggToken, "HenHouse EGG Token", "EGG").then(() => eggAddress = HenHouseEggToken.address))
            )    
    ]);

    instances = await Promise.all([
        HenHouseRouter.deployed(),
        HenHouseToken.deployed(),
        HenHouseEggToken.deployed(),
    ])

    router = instances[0];
    token = instances[1];
    egg = instances[2];
    
    console.log("Contract Router deployed to:", router.address);
    console.log("Contract Token deployed to:", token.address);
    console.log("Contract EGG deployed to:", egg.address);

    results = await Promise.all([
        router.setFeeAddress(token.address)
    ]);
};
