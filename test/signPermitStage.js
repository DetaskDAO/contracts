
async function signPermitStage(
  chainId,
  contractAddress,
  worker,
  orderId,
  amounts,
  periods,
  payType,
  nonce,
  deadline,
) {
  const domain = {
    name: "DetaskOrder",
    version: "1",
    chainId,
    verifyingContract: contractAddress,
  };

  const types = {
    PermitStage: [{ name: "orderId", type: "uint256" },
    { name: "amounts", type: "uint256[]" },
    { name: "periods", type: "uint256[]" },
    { name: "payType", type: "uint256" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  };

  const sig = await worker._signTypedData(domain, types, {
    orderId: orderId,
    amounts: amounts,
    periods: periods,
    payType: payType,
    nonce: nonce,
    deadline: deadline,
  });

  return sig
}


async function signPermitProlongStage(
  chainId,
  contractAddress,
  worker,
  orderId,
  stageIndex,
  period,
  nonce,
  deadline,
) {
  const domain = {
    name: "DetaskOrder",
    version: "1",
    chainId,
    verifyingContract: contractAddress,
  };

  const types = {
    PermitProStage: [{ name: "orderId", type: "uint256" },
    { name: "stageIndex", type: "uint256" },
    { name: "period", type: "uint256" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  };

  const sig = await worker._signTypedData(domain, types, {
    orderId: orderId,
    stageIndex: stageIndex,
    period: period,
    nonce: nonce,
    deadline: deadline,
  });

  return sig
}

module.exports = {
  signPermitStage,
  signPermitProlongStage
}