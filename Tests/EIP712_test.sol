pragma solidity ^0.8.12;

contract Verifier {
    uint256 constant chainId = 4;
    address constant verifyingContract = 0x1C56346CD2A2Bf3202F771f50d3D14a367B48070;
    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
    
    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    // string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
    // string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";
    
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    // bytes32 private constant IDENTITY_TYPEHASH = keccak256(abi.encode(IDENTITY_TYPE));
    // bytes32 private constant BID_TYPEHASH = keccak256(abi.encode(BID_TYPE));
    bytes32 private constant DATA_TYPEHASH = keccak256(bytes("Data(string message)"));
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes("My amazing dApp")),
        keccak256(bytes("2")),
        chainId,
        verifyingContract,
        salt
    ));
    
    struct Data {
        string message;
    }

    // struct Identity {
    //     uint256 userId;
    //     address wallet;
    // }
    
    // struct Bid {
    //     uint256 amount;
    //     Identity bidder;
    // }
    
    // function hashIdentity(Identity memory identity) private pure returns (bytes32) {
    //     return keccak256(abi.encode(
    //         IDENTITY_TYPEHASH,
    //         identity.userId,
    //         identity.wallet
    //     ));
    // }
    
    // function hashBid(Bid memory bid) private pure returns (bytes32){
    //     return keccak256(abi.encodePacked(
    //         "\\x19\\x01",
    //         DOMAIN_SEPARATOR,
    //         keccak256(abi.encode(
    //             BID_TYPEHASH,
    //             bid.amount,
    //             hashIdentity(bid.bidder)
    //         ))
    //     ));
    // }

    // function verify(uint256 _userId, address _wallet, uint256 _amount, bytes memory sig) public pure returns (address) {
    //     Identity memory bidder = Identity({
    //         userId: _userId,
    //         wallet: _wallet
    //     });
        
    //     Bid memory bid = Bid({
    //         amount: _amount,
    //         bidder: bidder
    //     });
            
    //     (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
    //     return ecrecover(getEthSignedMessageHash(hashBid(bid)), v, r, s);
    // }

    function hashData(Data memory data) private pure returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                DATA_TYPEHASH,
                keccak256(bytes(data.message))
            ))
        ));
    }
    
    function verify(string memory message, bytes memory sig) public pure returns (address) {
        Data memory data = Data(message);
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        // (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig, (uint8, bytes32, bytes32));
        return ecrecover(hashData(data), v, r, s);
    }


    function splitSig(bytes memory sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

