
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import (get_caller_address)

from contracts.token.ITDERC20 import ITDERC20
from contracts.token.IERC20 import IERC20

from contracts.utils.Iplayers_registry import Iplayers_registry
from contracts.utils.Iex10 import Iex10


@storage_var
func new_tderc20_address() -> (new_tderc20_address: felt):
end

@storage_var
func old_tderc20_address() -> (old_tderc20_address: felt):
end

@storage_var
func players_registry() -> (players_registry: felt):
end

@storage_var
func ex_registry(rank: felt) -> (address: felt):
end

@view
func ex_registry_view{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(rank: felt) -> (address: felt):
    let (address) = ex_registry.read(rank)
    return (address)
end

######### Constructor
# This function is called when the contract is deployed
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _old_tderc20_address: felt,
        _new_tderc20_address: felt,
        _players_registry: felt
    ):
    old_tderc20_address.write(_old_tderc20_address)
    new_tderc20_address.write(_new_tderc20_address)
    players_registry.write(_players_registry)
    return ()
end

######### External functions
# These functions are callable by other contracts
#

# This function is called claim_points
# It takes one argument as a parameter (sender_address), which is a felt. Read more about felts here https://www.cairo-lang.org/docs/hello_cairo/intro.html#field-element
# It also has implicit arguments (syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr). Read more about implicit arguments here TODO
@external
func set_exercices{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(ex_len: felt, ex: felt*):
    _set_exercices(ex_len, ex)

    return ()
end

@external
func process_accounts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(accounts_len: felt, accounts: felt*):
    _process_accounts(accounts_len, accounts)

    return()
end

func _set_exercices{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(ex_len: felt, ex: felt*):

    if ex_len == 0:
        return ()
    end

    # If length is NOT zero, then the function calls itself again, by moving forward one slot
    _set_exercices(ex_len=ex_len - 1, ex=ex + 1)

    # This part of the function is first reached when length=0.
    ex_registry.write(ex_len, [ex])
    return ()
end

func _process_accounts{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(accounts_len: felt, accounts: felt*):

    if accounts_len == 0:
        return ()
    end

    # If length is NOT zero, then the function calls itself again, by moving forward one slot
    _process_accounts(accounts_len=accounts_len - 1, accounts=accounts + 1)

    # Credit points
    let (old_erc20_address_) = old_tderc20_address.read()
    let (new_erc20_address_) = new_tderc20_address.read()
    let (balance) = IERC20.balanceOf(contract_address = old_erc20_address_, account = [accounts])
    ITDERC20.distribute_points(contract_address = new_erc20_address_, to = [accounts], amount = balance)

    # Validate exercices
    _process_an_account(11, [accounts])

    return ()
end

func _process_an_account{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(ex_number:felt, account: felt):

    if ex_number == 0:
        return ()
    end

    # If length is NOT zero, then the function calls itself again, by moving forward one slot
    _process_an_account(ex_number=ex_number - 1, account = account)

    # Validate exercices
    let (ex_address) = ex_registry.read(ex_number)
    let (has_validated) = Iex10.has_validated_exercice(contract_address = ex_address,account=account)

    if has_validated == 1:
        
        let (players_registry_address) = players_registry.read()

        Iplayers_registry.validate_exercice(contract_address = players_registry_address, account = account, workshop = 1, exercise=ex_number)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end







