'use client';

import { useEffect } from 'react';
import { use--Name--$ } from './--name--.store';
import { Handler, WildcardHandler } from 'mitt';
import { emitter, Events } from './--name--.events';

export interface Init--Name--$Props {}

export const Init--Name--$: React.FC<Init--Name--$Props> = () => {
	const { init, destroy } = use--Name--$();

	useEffect(() => {
		init();
		return () => destroy();
	}, [init, destroy]);

	return null;
};

export function use--Name--$Event(type: '*', handler: WildcardHandler<Events>): void;
export function use--Name--$Event<K extends keyof Events>(type: K, handler: Handler<Events[K]>): void;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function use--Name--$Event(type: any, handler: any) {
	useEffect(() => {
		emitter.on(type, handler);
		return () => emitter.off(type, handler);
	}, [type, handler]);
}
