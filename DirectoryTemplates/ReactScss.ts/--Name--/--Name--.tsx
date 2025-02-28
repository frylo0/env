import cn from 'clsx';
import s from './--Name--.module.scss';

export interface --Name--Props {
	className?: string;
}

export const --Name--: React.FC<--Name--Props> = ({
	className = '',
}) => {
	return (
		<div className={cn(s.root, className)}>

		</div>
	);
};
