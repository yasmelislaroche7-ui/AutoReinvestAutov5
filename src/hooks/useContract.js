import { useReadContract, useWriteContract, useWaitForTransactionReceipt, useAccount } from "wagmi";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "../config/contract.js";

export function useContractRead(functionName, args = [], watch = false) {
  return useReadContract({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    functionName,
    args,
    query: { refetchInterval: watch ? 10000 : false },
  });
}

export function useContractWrite() {
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const write = async (functionName, args = []) => {
    return writeContractAsync({
      address: CONTRACT_ADDRESS,
      abi: CONTRACT_ABI,
      functionName,
      args,
    });
  };

  return { write, hash, isPending, isConfirming, isSuccess, error };
}

export function useIsOwner() {
  const { address } = useAccount();
  const { data } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    functionName: "isOwner",
    args: [address ?? "0x0000000000000000000000000000000000000000"],
    query: { enabled: !!address },
  });
  return !!data;
}

export function useIsPrimaryOwner() {
  const { address } = useAccount();
  const { data } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    functionName: "primaryOwner",
  });
  return address && data && address.toLowerCase() === data.toLowerCase();
}
