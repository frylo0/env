import { observer } from "mobx-react-lite";

import {
	--Name--Component as Component,
	ComponentProps,
	LogicalProps,
} from "./--Name--";

export interface --Name--Props extends ComponentProps {}

export const --Name--: React.FC<--Name--Props> = observer(({ ...props }) => {
	return (
		<Component
			{...props}
		/>
	);
});
