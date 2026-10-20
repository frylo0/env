import { create, StateCreator } from 'zustand';
import { emitter } from './--name--.events';
import { immer } from 'zustand/middleware/immer';

interface IMeta {
	init: () => Promise<void>;
	destroy: () => void;
	derived: () => IDerived;
	ready: boolean;
}

interface IDerived {}

interface IState {}

interface IActions {}

export interface IStore extends IState, IActions, IMeta {}

const initialState: IState & Pick<IMeta, 'ready'> = {
    ready: false,
};

const events = emitter;

const creator: StateCreator<IStore, [['zustand/immer', never]]> = (set, get) => ({
	...initialState,

	init: async () => {
		set({ ready: true });
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
