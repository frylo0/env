import cn from "classnames";
import s from "./--Name--.module.scss";

export interface ComponentProps {
	className?: string;
}
export interface LogicalProps {}
export interface --Name--ComponentProps extends ComponentProps, LogicalProps {}

export const --Name--Component: React.FC<--Name--ComponentProps> = ({
	className = "",
}) => {
	return (
		<div className={cn(s.--naMe--, className)}>

		</div>
	);
};
