import mitt from 'mitt';

/** @see https://www.npmjs.com/package/mitt#typescript */
export type Events = {
	'event/start': void;
	'event/succeed': void;
	'event/error': { key: 'failedRequest'; error: V1FrontendError } | { key: 'tokenEmpty' };
};

export const emitter = mitt<Events>();
