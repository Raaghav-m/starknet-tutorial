#[starknet::interface]
trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}
trait Event<T> {
    fn increase_counter(ref self: T);
}

#[starknet::contract]
pub mod counter_contract {
    use OwnableComponent::InternalTrait;
    use openzeppelin_access::ownable::interface::IOwnableTwoStepCamelOnly;
    use openzeppelin_access::ownable::interface::IOwnable;
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
    use starknet::event::EventEmitter;
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[storage]
    struct Storage {
        counter: u32,
        kill_switch_address: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }
    #[derive(Drop, starknet::Event)]
    struct CounterIncrease {
        #[key]
        value: u32,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncrease,
        OwnableEvent: OwnableComponent::Event
    }
    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_value: u32,
        kill_switch: ContractAddress,
        initial_owner: ContractAddress
    ) {
        self.counter.write(initial_value);
        self.kill_switch_address.write(kill_switch);
        self.ownable.initializer(initial_owner);
    }
    #[abi(embed_v0)]
    impl counter_contract of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let kill_switch_dispatcher = IKillSwitchDispatcher {
                contract_address: self.kill_switch_address.read()
            };
            let is_active = kill_switch_dispatcher.is_active();
            assert!(!is_active, "KillSwitch is active");
            let count = self.counter.read();
            self.counter.write(count + 1);
            let updatedVal = self.counter.read();
            self.emit(CounterIncrease { value: updatedVal });
        }
    }
}
