pragma solidity ^0.8.12;


contract Testsig {

    struct Order {
        string id;
        uint256 amount;
        address maker;
    }
    Order[] public orders;

    function addOrder(string memory id, uint256 amount, address maker, bytes memory sig) external {
        Order memory order = Order(id, amount, maker);
        require(validateOrder(order, sig), "Signer doesn't match");
        orders.push(order);
    }

    function getOrders() external view returns(Order[] memory) {
        return orders;
    }

    function validateOrder(Order memory order, bytes memory sig) internal returns(bool) {
        bytes32 orderHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(order.id, order.amount, order.maker))));
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        address signer = ecrecover(orderHash, v, r, s);
        return order.maker == signer;
    }

    function getSigner(string memory id, uint256 amount, address maker, bytes memory sig) external pure returns(address) {
        bytes32 orderHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(id, amount, maker))));
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return ecrecover(orderHash, v, r, s);
    }

    function getSignerFromSimpleMessage(string memory message, bytes memory sig) external pure returns(address) {
        bytes32 orderHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(message))));
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return ecrecover(orderHash, v, r, s);
    }

    function splitSig(bytes memory sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getMessageHash(
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

}
