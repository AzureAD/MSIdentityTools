import React from 'react';
import { useCurrentSidebarCategory, filterDocCardListItems } from '@docusaurus/theme-common';
import { useDocById } from '@docusaurus/plugin-content-docs/client';
import Link from '@docusaurus/Link';
import type { Props } from '@theme/DocCardList';
import styles from './styles.module.css';

function DocCardListForCurrentSidebarCategory({ className }: Props) {
    const category = useCurrentSidebarCategory();
    return <DocLinkList items={category.items} className={className} />;
}

export default function DocLinkList(props: Props): JSX.Element {
    const { items, className } = props;
    if (!items) {
        return <DocCardListForCurrentSidebarCategory {...props} />;
    }
    const filteredItems = filterDocCardListItems(items);

    return (
        <ul className={className}>
            {filteredItems.map((item, index) => {
                if (item.type === 'link') {
                    return <DocLink key={item.docId || index} item={item} />;
                }
                if (item.type === 'category') {
                    return <DocCategoryLink key={item.href || index} category={item} />;
                }
                return null;
            })}
        </ul>
    );
}

function DocLink({ item }) {
    const doc = useDocById(item.docId);
    const description = item.description || item.customProps?.description || doc?.description;
    return (
        <li className="margin-bottom--md">
            <Link to={item.href}>{item.label}</Link>
            {description && (
                <>
                    <br />
                    <small className={styles.description}>{description}</small>
                </>
            )}
        </li>
    );
}

function DocCategoryLink({ category }) {
    // For categories, try to find the first link in the category
    const categoryHref = category.href || '#';
    const description = category.description || category.customProps?.description;

    return (
        <li className="margin-bottom--md">
            <Link to={categoryHref}>{category.label}</Link>
            {description && (
                <>
                    <br />
                    <small className={styles.description}>{description}</small>
                </>
            )}
        </li>
    );
}
