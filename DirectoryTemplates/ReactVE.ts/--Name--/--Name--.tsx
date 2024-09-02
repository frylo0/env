import cn from 'clsx';

import { s--Name-- } from './--Name--.css';

export interface --Name--Props {
	className?: string;
}

export const --Name--: React.FC<--Name--Props> = ({
	className = '',
}) => {
	return (
		<div className={cn(s--Name--, className)}>

		</div>
	);
};
