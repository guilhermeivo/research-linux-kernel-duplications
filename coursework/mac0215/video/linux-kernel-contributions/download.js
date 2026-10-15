import fs from "fs/promises";
import { existsSync } from 'node:fs';

const token = "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";
const owner = "torvalds"
const repo = "linux"

async function getAuthorUser(hash) {
    let request = await fetch(`https://api.github.com/repos/${owner}/${repo}/commits/${hash}`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
            "Authorization": `Bearer ${token}`,
        }
    });

    if (!request.ok)
        return undefined

    const commit = await request.json();
    return commit.author;
}

async function getAuthor() {
    try {
        const text = await fs.readFile("authors.txt", "utf8");

        const lines = text.split("\n")
        return lines.map(line => {
            const values = line.split(" ")
            return {
                "commits": values[0],
                "email": values[1],
                "hash": values[2]
            }
        })
    } catch (error) {
        console.error(error.message);
    }
    return []
}

async function downloadImage(url, filename) {
    const response = await fetch(url);

    const buffer = await response.arrayBuffer();

    await fs.writeFile(
        filename,
        Buffer.from(buffer)
    );
}

(async () => {
    const authors = await getAuthor()

    const maxLoop = Math.min(500, authors.length)

    for (let index = 0; index < maxLoop; index++) {
        const filename = `avatars/${authors[index].email}.png`;
        if (existsSync(filename))
            continue

        const user = await getAuthorUser(authors[index].hash)

        if (!user)
            continue;

        await downloadImage(user.avatar_url, filename);

        console.log(
            authors[index].email,
            "->",
            filename
        );
    }
})()
