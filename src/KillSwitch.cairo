#[starknet::contract]
pub mod KillSwitch {
    #[storage]
    struct Storage {
        kill_switch: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, kill_switch_address: ContractAddress) {
        self.kill_switch.write(kill_switch_address);
    }
}
