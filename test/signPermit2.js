
async function signPermit2(
    chainId,
    permit2Address,
    worker,
    token,
    amount,
    spender,
    nonce,
    deadline,
  ) {
      
    const domain = {
      name: "Permit2",
      chainId,
      verifyingContract: permit2Address,
    };
  
    const types = {
        PermitTransferFrom: [
            { name: 'permitted', type: 'TokenPermissions' },
            { name: 'spender', type: 'address' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' },
        ],
        TokenPermissions: [
            { name: 'token', type: 'address' },
            { name: 'amount', type: 'uint256' },
        ]
    };

    console.log('sign ==>',domain, types, {
      permitted: {
        token: token,
        amount: amount
      },
      spender: spender,
      nonce: nonce,
      deadline: deadline
    });
  
    const sig = await worker._signTypedData(domain, types, {
        permitted: {
          token: token,
          amount: amount
        },
        spender: spender,
        nonce: nonce,
        deadline: deadline
      });
  
    return sig
  }
  
  
  module.exports = {
    signPermit2
  }