const BASE_URL = "http://localhost:5000/api";

async function request(
    path: string,
    options: RequestInit = {}
) {
    const token = localStorage.getItem("token");

    const headers: Record<string, string> = {
        "Content-Type": "application/json",
        ...((options.headers as Record<string, string>) || {}),
    };

    if (token) {
        headers["Authorization"] = `Bearer ${token}`;
    }

    const response = await fetch(`${BASE_URL}${path}`, {
        ...options,
        headers,
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(error || `Request failed: ${response.status}`);
    }

    if (response.status === 204) {
        return null;
    }

    const json = await response.json();
    return json.data !== undefined ? json.data : json;
}

export const api = {
    get: (path: string) =>
        request(path, {
            method: "GET",
        }),

    post: (path: string, data: unknown) =>
        request(path, {
            method: "POST",
            body: JSON.stringify(data),
        }),

    patch: (path: string, data: unknown) =>
        request(path, {
            method: "PATCH",
            body: JSON.stringify(data),
        }),

    delete: (path: string) =>
        request(path, {
            method: "DELETE",
        }),
};