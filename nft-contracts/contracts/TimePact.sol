// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/basic-deal-client/DealClient.sol";

error TimePact__EmptyKey();
error TimePact__NotEnoughTimePassed();
error TimePact__CallerIsNotOwnerNorApproved();
error TimePact__TokenDoesNotExist();
error TimePact__AlreadyUnlocked();
error TimePact__CidExists();

contract TimePact is ERC721Enumerable {
    struct PactInfo {
        string creator; // reference to the creator of the Pact
        uint64 unlock; // unix timestamp
        string CID; // reference to the encrypted storage piece CID
        bool locked; //Pact locked or unlocked
        uint64 erase; //unlock + delay (UNIX)
        bool filecoin;
    }

    mapping(uint256 => PactInfo) internal keys;
    mapping(uint256 => string) internal cidCheck;

    uint64 constant delay = 24 weeks;
    uint256 private number;
    DealClient public dealsClient;
    address public owner;

    constructor() ERC721("TimePact", "TP") {
        dealsClient = new DealClient();
        owner = msg.sender;
    }

    event Pact(string cid, string creator, uint64 edate); //Creation of the Pact
    event Unlocked(uint256 tokenId, address owner, string cid); //Unlocking the file (expiration of the Pact)
    event PactWithFilecoin(string pcid, string creator, uint64 edate);

    /// @notice Creates the record of the tokenId -> CID pair
    /// @param cid IPFS pointer
    /// @param creator Original creator of the Pact
    /// @param edate The expiry date in UNIX format
    function pact(string memory cid, string memory creator, uint64 edate) external {
        if (keccak256(abi.encode(cid)) == keccak256(abi.encode(""))) {
            revert TimePact__EmptyKey();
        }
        if (!cidSybil(cid)) {
            revert TimePact__CidExists();
        }

        cidCheck[number] = cid;
        PactInfo storage info = keys[number];
        info.creator = creator;
        info.unlock = edate;
        info.CID = cid;
        info.locked = true;
        info.filecoin = false;
        info.erase = edate + delay;


        _safeMint(msg.sender, number); //Only works with ERC721 reciever/holder in the case with smart contracts
        ++number;
        emit Pact(cid, creator, edate);
    }

    /// @notice Creates the record of the tokenId -> CID pair
    /// @param pcid piece_cid or car
    function pactFilecoin(string memory pcid, uint256 tokenId, DealRequest calldata deal) external {
        if (keccak256(abi.encode(pcid)) == keccak256(abi.encode(""))) {
            revert TimePact__EmptyKey();
        }

        dealsClient.makeDealProposal(deal);

        PactInfo storage info = keys[number];
        info.CID = pcid;
        info.filecoin = false;

        emit PactWithFilecoin(pcid, keys[number].creator, keys[number].unlock);
    }

    /// @notice Unlocks the file and emits the event
    /// @param tokenId The NFT to get the user address for
    function unlock(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TimePact__CallerIsNotOwnerNorApproved();
        }
        if (!checkUnlock(tokenId)) {
            revert TimePact__NotEnoughTimePassed();
        }

        keys[tokenId].locked = false;

        emit Unlocked(tokenId, msg.sender, keys[tokenId].CID);
    }

    /// @notice gives out details on specific deal
    function tokenInfo(
        uint256 tokenId
    ) public view returns (string memory, uint64, string memory, bool, uint64, bool) {
        return (
            keys[tokenId].creator,
            keys[tokenId].unlock,
            keys[tokenId].CID,
            keys[tokenId].locked,
            keys[tokenId].erase,
            keys[tokenId].filecoin
        );
    }

    /// @notice Checks if the files can be unlocked
    /// @dev True => can be unlocked
    /// @param tokenId The NFT to get the user address for
    function checkUnlock(uint256 tokenId) public view returns (bool) {
        if (uint256(keys[tokenId].unlock) <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice Checks if the files were outdated and deleted
    /// @dev True => deleted
    /// @param tokenId The NFT to get the user address for
    function checkDelete(uint256 tokenId) public view returns (bool) {
        if (uint256((keys[tokenId].unlock) + delay) <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TimePact__TokenDoesNotExist();
        }
        return _baseURI();
    }

    function getDelay() public pure returns (uint256) {
        return delay;
    }

    /**
     * @dev Token becomes wallet-bound after Pact is unlocked (to prevent malicious trading)
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        if (!keys[tokenId].locked) {
            revert TimePact__AlreadyUnlocked();
        }
        super._transfer(from, to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafyreic3rh2kbw5ulhlq67nu4e65p37acfitkgqglxhn7o3ima7pstn56m/metadata.json";
    }

    function cidSybil(string memory cid) internal view returns (bool) {
        for (uint i = 0; i <= number; ++i) {
            if (keccak256(abi.encode(cid)) == keccak256(abi.encode(cidCheck[i]))) {
                return false;
            }
        }
        return true;
    }

    //////////////////////Panel for Deal Client (with access control)////////////
    // addBalance funds the builtin storage market actor's escrow
    // with funds from the contract's own balance
    // @value - amount to be added in escrow in attoFIL
    function addBalanceClient(uint256 value) public {
        dealsClient.addBalance(value);
    }

    // This function attempts to withdraw the specified amount from the contract addr's escrow balance
    // If less than the given amount is available, the full escrow balance is withdrawn
    // @client - Eth address where the balance is withdrawn to. This can be the contract address or an external address
    // @value - amount to be withdrawn in escrow in attoFIL
    function withdrawBalanceClient(address client, uint256 value) public {
        require(msg.sender == owner);
        dealsClient.withdrawBalance(client, value);
    }

    function getDealClient() public view returns (address) {
        return address(dealsClient);
    }
}
