import { create, StateCreator } from 'zustand';
import { emitter } from './--name--.events';
import { immer } from 'zustand/middleware/immer';

interface IDerived {}

interface IMeta {
	init: () => Promise<void>;
	destroy: () => void;
	initting: boolean;

	derived: () => IDerived;
}

interface IState {}

interface IActions {}

export interface IStore extends IState, IActions, IMeta {}

const initialState: IState = {
    // ..
};

const events = emitter;

const creator: StateCreator<IStore, [['zustand/immer', never]]> = (set, get) => ({
	initting: true,

	...initialState,

	init: async () => {
		set({ initting: true });
		
        // ...

		set({ initting: false });
	},

	derived: () => {
		const $ = get();

		return {};
	},

	destroy: () => {
		set(initialState);
	},
});

export const use--Name--$ = create<IStore>()(immer(creator));
