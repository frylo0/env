import styles from './--Name--.module.scss';
import classNames from 'classnames/bind';
const cx = classNames.bind(styles);

interface --Name--Props extends React.PropsWithChildren {
	className?: string,
};

export const --Name--: React.FC<--Name--Props> = ({
	className = '',
}) => {
	return (
		<div className={cx('--na-me--', className)}>
			
		</div>
	);
};
