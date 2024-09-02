import { --Name-- } from './--Name--';

import type { Meta, StoryObj } from '@storybook/react';

const meta = {
	title: 'Common/--Name--',
	component: --Name--,
	parameters: {
		layout: 'centered',
	},
	tags: ['autodocs'],
	argTypes: {},
} satisfies Meta<typeof --Name-->;

export default meta;

type Story = StoryObj<typeof meta>;

export const Primary: Story = {
	args: {

	},
};